@isTest
private class OpenWeatherControllerTest {
    private static final String CURRENT_BODY =
        '{"weather":[{"id":803,"main":"Clouds","description":"broken clouds","icon":"04d"}],' +
        '"main":{"temp":39.31,"feels_like":42.65,"pressure":999,"humidity":32},' +
        '"visibility":10000,"wind":{"speed":3.78,"deg":277},"dt":1784359315,' +
        '"clouds":{"all":79},' +
        '"sys":{"country":"IN","sunrise":1784332903,"sunset":1784382520},' +
        '"timezone":19800,"name":"Meerut","cod":200}';

    // Two slots on day one (09:00 and 12:00 local) and one on day two, so the
    // rollup has something to pick a high, a low and a midday icon from.
    private static final String FORECAST_BODY =
        '{"list":[' +
        '{"dt":1784365200,"main":{"temp":39.32,"temp_min":39.32,"temp_max":40.48,"humidity":32,"dew_point":19.58},' +
        '"weather":[{"icon":"04d","description":"broken clouds"}],"wind":{"speed":3.48,"deg":321},"pop":0},' +
        '{"dt":1784376000,"main":{"temp":41.00,"temp_min":38.00,"temp_max":42.00,"humidity":30,"dew_point":19.10},' +
        '"weather":[{"icon":"01d","description":"clear sky"}],"wind":{"speed":4.00,"deg":300},"pop":0.25},' +
        '{"dt":1784451600,"main":{"temp":33.00,"temp_min":30.00,"temp_max":34.00,"humidity":45,"dew_point":20.00},' +
        '"weather":[{"icon":"10d","description":"light rain"}],"wind":{"speed":2.00,"deg":180},"pop":0.6}' +
        '],"city":{"name":"Meerut","country":"IN","timezone":19800}}';

    private class WeatherMock implements HttpCalloutMock {
        private Integer statusCode;

        private WeatherMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                req.getEndpoint().contains('/forecast') ? FORECAST_BODY : CURRENT_BODY
            );
            return res;
        }
    }

    @isTest
    static void returnsCurrentConditions() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(200));

        Test.startTest();
        OpenWeatherController.WeatherPayload payload = OpenWeatherController.getWeather(
            'Meerut'
        );
        Test.stopTest();

        Assert.areEqual('Meerut', payload.city);
        Assert.areEqual('IN', payload.country);
        Assert.areEqual(19800, payload.tzOffsetSeconds);
        Assert.areEqual(39.31, payload.current.temp);
        Assert.areEqual(42.65, payload.current.feelsLike);
        Assert.areEqual('Broken clouds', payload.current.description);
        Assert.areEqual(32, payload.current.humidity);
        Assert.areEqual(999, payload.current.pressure);
        Assert.areEqual(10.0, payload.current.visibilityKm);
        Assert.areEqual(19.58, payload.current.dewPoint, 'dew point comes from the forecast feed');
        Assert.areEqual(79, payload.current.cloudCover);
        Assert.areEqual(1784332903L, payload.current.sunrise);
        Assert.areEqual(1784382520L, payload.current.sunset);
    }

    @isTest
    static void mapsHourlySlots() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(200));

        Test.startTest();
        OpenWeatherController.WeatherPayload payload = OpenWeatherController.getWeather(
            'Meerut'
        );
        Test.stopTest();

        Assert.areEqual(3, payload.hourly.size());
        Assert.areEqual(0, payload.hourly[0].pop);
        Assert.areEqual(25, payload.hourly[1].pop, 'pop is converted to a percentage');
        Assert.areEqual(60, payload.hourly[2].pop);
        Assert.areEqual('04d', payload.hourly[0].icon);
    }

    @isTest
    static void rollsForecastSlotsIntoDays() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(200));

        Test.startTest();
        OpenWeatherController.WeatherPayload payload = OpenWeatherController.getWeather(
            'Meerut'
        );
        Test.stopTest();

        Assert.areEqual(2, payload.daily.size(), 'three slots span two local days');
        Assert.areEqual(42.00, payload.daily[0].tempMax, 'day one takes the higher max');
        Assert.areEqual(38.00, payload.daily[0].tempMin, 'day one takes the lower min');
        Assert.areEqual(34.00, payload.daily[1].tempMax);
    }

    @isTest
    static void blankCityIsRejectedWithoutCallout() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(200));

        Boolean threw = false;
        Test.startTest();
        try {
            OpenWeatherController.getWeather('   ');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'a blank city should be rejected before the callout');
    }

    @isTest
    static void unknownCitySurfacesFriendlyError() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(404));

        Boolean threw = false;
        Test.startTest();
        try {
            OpenWeatherController.getWeather('Nowhereville');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'a 404 from the API should raise an AuraHandledException');
    }

    @isTest
    static void rejectedApiKeySurfacesFriendlyError() {
        Test.setMock(HttpCalloutMock.class, new WeatherMock(401));

        Boolean threw = false;
        Test.startTest();
        try {
            OpenWeatherController.getWeather('Meerut');
        } catch (AuraHandledException e) {
            threw = true;
        }
        Test.stopTest();

        Assert.isTrue(threw, 'a 401 from the API should raise an AuraHandledException');
    }
}