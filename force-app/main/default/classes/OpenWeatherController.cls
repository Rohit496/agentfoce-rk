/**
 * Aggregates OpenWeatherMap current-conditions and 5-day/3-hour forecast into a
 * single payload for the weatherForecast LWC.
 *
 * All temperatures are returned in Celsius and wind in m/s; the component does
 * the C -> F toggle client-side so switching units never costs another callout.
 */
public with sharing class OpenWeatherController {
    private static final String NAMED_CREDENTIAL = 'callout:OpenWeatherMap';
    private static final Integer DAILY_SLOTS = 6;

    public class WeatherException extends Exception {
    }

    public class Slot {
        @AuraEnabled
        public Long dt;
        @AuraEnabled
        public Decimal temp;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public Integer pop;
        /** Local calendar day this slot belongs to, so the UI can filter by day. */
        @AuraEnabled
        public Long dayKey;
    }

    public class Day {
        @AuraEnabled
        public Long dt;
        @AuraEnabled
        public Long dayKey;
        @AuraEnabled
        public Decimal tempMax;
        @AuraEnabled
        public Decimal tempMin;
        @AuraEnabled
        public String icon;
    }

    public class Current {
        @AuraEnabled
        public Decimal temp;
        @AuraEnabled
        public Decimal feelsLike;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String icon;
        @AuraEnabled
        public Decimal windSpeed;
        @AuraEnabled
        public Integer windDeg;
        @AuraEnabled
        public Integer humidity;
        @AuraEnabled
        public Decimal visibilityKm;
        @AuraEnabled
        public Integer pressure;
        @AuraEnabled
        public Decimal dewPoint;
        @AuraEnabled
        public Integer cloudCover;
        @AuraEnabled
        public Long sunrise;
        @AuraEnabled
        public Long sunset;
    }

    public class WeatherPayload {
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public Integer tzOffsetSeconds;
        @AuraEnabled
        public Long observedAt;
        @AuraEnabled
        public Current current;
        @AuraEnabled
        public List<Slot> hourly = new List<Slot>();
        @AuraEnabled
        public List<Day> daily = new List<Day>();
    }

    @AuraEnabled
    public static WeatherPayload getWeather(String city) {
        if (String.isBlank(city)) {
            throw new AuraHandledException('Enter a city name.');
        }

        String q = EncodingUtil.urlEncode(city.trim(), 'UTF-8');
        Map<String, Object> currentRaw = callApi('/data/2.5/weather?units=metric&q=' + q);
        Map<String, Object> forecastRaw = callApi('/data/2.5/forecast?units=metric&q=' + q);

        WeatherPayload payload = new WeatherPayload();
        payload.city = (String) currentRaw.get('name');
        payload.tzOffsetSeconds = toInteger(currentRaw.get('timezone'));
        payload.observedAt = toLong(currentRaw.get('dt'));

        Map<String, Object> sys = (Map<String, Object>) currentRaw.get('sys');
        if (sys != null) {
            payload.country = (String) sys.get('country');
        }

        payload.current = buildCurrent(currentRaw);

        List<Object> slots = (List<Object>) forecastRaw.get('list');
        if (slots != null && !slots.isEmpty()) {
            // dew_point is only present on forecast entries, not on /weather.
            Map<String, Object> firstMain = (Map<String, Object>) ((Map<String, Object>) slots[0])
                .get('main');
            payload.current.dewPoint = toDecimal(firstMain.get('dew_point'));

            payload.hourly = buildHourly(slots, payload.tzOffsetSeconds);
            payload.daily = buildDaily(slots, payload.tzOffsetSeconds, payload.current);
        }

        return payload;
    }

    private static Map<String, Object> callApi(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod('GET');
        req.setTimeout(20000);

        HttpResponse res = new Http().send(req);
        Integer status = res.getStatusCode();

        if (status == 404) {
            throw new AuraHandledException('City not found. Check the spelling and try again.');
        }
        if (status == 401) {
            throw new AuraHandledException(
                'OpenWeatherMap rejected the API key. Set the ApiKey auth parameter on the OpenWeatherMap external credential.'
            );
        }
        if (status != 200) {
            throw new AuraHandledException('Weather service returned HTTP ' + status + '.');
        }

        return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    }

    private static Current buildCurrent(Map<String, Object> raw) {
        Current c = new Current();

        Map<String, Object> main = (Map<String, Object>) raw.get('main');
        if (main != null) {
            c.temp = toDecimal(main.get('temp'));
            c.feelsLike = toDecimal(main.get('feels_like'));
            c.humidity = toInteger(main.get('humidity'));
            c.pressure = toInteger(main.get('pressure'));
        }

        Map<String, Object> wind = (Map<String, Object>) raw.get('wind');
        if (wind != null) {
            c.windSpeed = toDecimal(wind.get('speed'));
            c.windDeg = toInteger(wind.get('deg'));
        }

        Integer visibilityMetres = toInteger(raw.get('visibility'));
        if (visibilityMetres != null) {
            c.visibilityKm = (Decimal.valueOf(visibilityMetres) / 1000).setScale(1);
        }

        Map<String, Object> clouds = (Map<String, Object>) raw.get('clouds');
        if (clouds != null) {
            c.cloudCover = toInteger(clouds.get('all'));
        }

        Map<String, Object> sys = (Map<String, Object>) raw.get('sys');
        if (sys != null) {
            c.sunrise = toLong(sys.get('sunrise'));
            c.sunset = toLong(sys.get('sunset'));
        }

        Map<String, Object> condition = firstCondition(raw);
        if (condition != null) {
            c.description = capitalise((String) condition.get('description'));
            c.icon = (String) condition.get('icon');
        }

        return c;
    }

    /**
     * Returns every forecast slot tagged with its local calendar day. The component
     * filters by day rather than re-calling out when the user picks a day.
     */
    private static List<Slot> buildHourly(List<Object> slots, Integer tzOffsetSeconds) {
        Integer offset = tzOffsetSeconds == null ? 0 : tzOffsetSeconds;
        List<Slot> hourly = new List<Slot>();

        for (Object item : slots) {
            Map<String, Object> entry = (Map<String, Object>) item;
            Map<String, Object> main = (Map<String, Object>) entry.get('main');
            Map<String, Object> condition = firstCondition(entry);

            Slot s = new Slot();
            s.dt = toLong(entry.get('dt'));
            s.dayKey = (s.dt + offset) / 86400;
            s.temp = toDecimal(main.get('temp'));
            s.icon = condition == null ? null : (String) condition.get('icon');

            Decimal pop = toDecimal(entry.get('pop'));
            s.pop = pop == null ? 0 : (pop * 100).round().intValue();

            hourly.add(s);
        }

        return hourly;
    }

    /**
     * Rolls the 3-hourly slots up into calendar days in the city's own timezone,
     * taking each day's high/low and the icon closest to local midday.
     */
    private static List<Day> buildDaily(
        List<Object> slots,
        Integer tzOffsetSeconds,
        Current currentConditions
    ) {
        Integer offset = tzOffsetSeconds == null ? 0 : tzOffsetSeconds;

        List<Long> order = new List<Long>();
        Map<Long, Day> byDay = new Map<Long, Day>();
        Map<Long, Integer> middayGap = new Map<Long, Integer>();

        for (Object item : slots) {
            Map<String, Object> entry = (Map<String, Object>) item;
            Long dt = toLong(entry.get('dt'));
            Long localSeconds = dt + offset;
            Long dayKey = localSeconds / 86400;
            Long secondsIntoDay = Math.mod(localSeconds, 86400);

            Map<String, Object> main = (Map<String, Object>) entry.get('main');
            Decimal high = toDecimal(main.get('temp_max'));
            Decimal low = toDecimal(main.get('temp_min'));

            Day d = byDay.get(dayKey);
            if (d == null) {
                d = new Day();
                d.dayKey = dayKey;
                d.dt = dayKey * 86400 - offset;
                d.tempMax = high;
                d.tempMin = low;
                byDay.put(dayKey, d);
                middayGap.put(dayKey, 2147483647);
                order.add(dayKey);
            } else {
                if (high != null && (d.tempMax == null || high > d.tempMax)) {
                    d.tempMax = high;
                }
                if (low != null && (d.tempMin == null || low < d.tempMin)) {
                    d.tempMin = low;
                }
            }

            Integer gap = Math.abs(secondsIntoDay - 43200).intValue();
            if (gap < middayGap.get(dayKey)) {
                middayGap.put(dayKey, gap);
                Map<String, Object> condition = firstCondition(entry);
                d.icon = condition == null ? null : (String) condition.get('icon');
            }
        }

        List<Day> daily = new List<Day>();
        for (Long dayKey : order) {
            if (daily.size() == DAILY_SLOTS) {
                break;
            }
            daily.add(byDay.get(dayKey));
        }

        // The forecast window can start mid-day, leaving today's high lower than
        // what is being observed right now. Never report a high below current temp.
        if (
            !daily.isEmpty() &&
            currentConditions.temp != null &&
            (daily[0].tempMax == null || currentConditions.temp > daily[0].tempMax)
        ) {
            daily[0].tempMax = currentConditions.temp;
        }

        return daily;
    }

    private static Map<String, Object> firstCondition(Map<String, Object> entry) {
        List<Object> weather = (List<Object>) entry.get('weather');
        if (weather == null || weather.isEmpty()) {
            return null;
        }
        return (Map<String, Object>) weather[0];
    }

    private static String capitalise(String value) {
        if (String.isBlank(value)) {
            return value;
        }
        return value.substring(0, 1).toUpperCase() + value.substring(1);
    }

    private static Decimal toDecimal(Object value) {
        if (value == null) {
            return null;
        }
        return Decimal.valueOf(String.valueOf(value));
    }

    private static Integer toInteger(Object value) {
        Decimal d = toDecimal(value);
        return d == null ? null : d.round().intValue();
    }

    private static Long toLong(Object value) {
        Decimal d = toDecimal(value);
        return d == null ? null : d.longValue();
    }
}