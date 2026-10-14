public with sharing class WeatherDemo {
    @AuraEnabled
    public static String getWeather(String city) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint(
            'callout:Weather_NC/current.json?q=' +
            EncodingUtil.urlEncode(city, 'UTF-8')
        );
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        return res.getBody();
    }
}