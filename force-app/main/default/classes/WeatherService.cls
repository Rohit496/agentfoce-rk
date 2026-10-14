@RestResource(urlMapping='/weather-service/*')
global with sharing class WeatherService {
    private static final String BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
    private static final String API_KEY = '08b02af48f7db29a5e2704b2331dcd06';

    @HttpGet
    global static void getWeather() {
        RestRequest req = RestContext.request;
        RestContext.response.addHeader('Content-Type', 'application/json');

        String city = req.params.get('city');

        if (String.isBlank(city)) {
            city = 'Delhi';
        }

        String endpoint =
            BASE_URL +
            '?q=' +
            EncodingUtil.urlEncode(city, 'UTF-8') +
            '&appid=' +
            API_KEY +
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