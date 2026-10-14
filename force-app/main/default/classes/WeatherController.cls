@RestResource(urlMapping='/weather/*')
global with sharing class WeatherController {
    private static final String NAMED_CREDENTIAL = 'callout:Weather_API_NEW';

    global class WeatherResponse {
        global String city;
        global Decimal temperature;
    }

    @HttpGet
    global static WeatherResponse getWeather() {
        RestRequest req = RestContext.request;

        String city = req.params.get('city');

        if (String.isBlank(city)) {
            city = 'Delhi';
        }

        String endpoint =
            NAMED_CREDENTIAL +
            '/current.json?q=' +
            EncodingUtil.urlEncode(city, 'UTF-8');

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endpoint);
        httpReq.setMethod('GET');

        Http http = new Http();
        HttpResponse httpRes = http.send(httpReq);

        if (httpRes.getStatusCode() != 200) {
            RestContext.response.statusCode = httpRes.getStatusCode();
            return null;
        }

        Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(
            httpRes.getBody()
        );
        Map<String, Object> location = (Map<String, Object>) raw.get(
            'location'
        );
        Map<String, Object> current = (Map<String, Object>) raw.get('current');

        WeatherResponse result = new WeatherResponse();
        result.city = (String) location.get('name');
        result.temperature = (Decimal) current.get('temp_c');

        return result;
    }
}