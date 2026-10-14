@RestResource(urlMapping='/contact-weather/*')
global with sharing class ContactWeatherController {
    private static final String NAMED_CREDENTIAL = 'callout:Weather_NC';

    global class WeatherResponse {
        global String contactId;
        global String contactName;
        global String city;
        global Decimal temperature;
    }

    @HttpGet
    global static WeatherResponse getContactWeather() {
        RestRequest req = RestContext.request;

        String contactId = req.params.get('contactId');

        if (String.isBlank(contactId)) {
            RestContext.response.statusCode = 400;
            return null;
        }

        Contact contact;
        try {
            contact = [
                SELECT Id, Name, MailingCity
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
        } catch (QueryException e) {
            RestContext.response.statusCode = 404;
            return null;
        }

        if (String.isBlank(contact.MailingCity)) {
            RestContext.response.statusCode = 422;
            return null;
        }

        String endpoint =
            NAMED_CREDENTIAL +
            '/current.json?q=' +
            EncodingUtil.urlEncode(contact.MailingCity, 'UTF-8');

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
        result.contactId = contact.Id;
        result.contactName = contact.Name;
        result.city = (String) location.get('name');
        result.temperature = (Decimal) current.get('temp_c');

        return result;
    }
}