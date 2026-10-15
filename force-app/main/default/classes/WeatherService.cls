@RestResource(urlMapping='/weather-service/*')
global with sharing class WeatherService {
    // The OpenWeatherMap named credential holds the host and adds the API key as the x-api-key header
    // (External Credential OpenWeatherMap, parameter appid). No key or URL lives in code.
    private static final String NAMED_CREDENTIAL = 'callout:OpenWeatherMap';

    @HttpGet
    global static void getWeather() {
        RestRequest req = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');

        String city = req.params.get('city');

        if (String.isBlank(city)) {
            city = 'Delhi';
        }

        String endpoint =
            NAMED_CREDENTIAL +
            '/data/2.5/weather?q=' +
            EncodingUtil.urlEncode(city, 'UTF-8') +
            '&units=metric';

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endpoint);
        httpReq.setMethod('GET');

        Http http = new Http();
        HttpResponse httpRes = http.send(httpReq);

        if (httpRes.getStatusCode() != 200) {
            RestContext.response.statusCode = httpRes.getStatusCode();
            RestContext.response.responseBody = Blob.valueOf(
                '{"error":"Failed to fetch weather data: ' + httpRes.getStatus() + '"}'
            );
            return;
        }

        Map<String, Object> raw = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
        Map<String, Object> mainData = (Map<String, Object>) raw.get('main');

        Map<String, Object> result = new Map<String, Object>{
            'city' => raw.get('name'),
            'temperature' => mainData.get('temp')
        };

        RestContext.response.responseBody = Blob.valueOf(JSON.serialize(result));
    }
}