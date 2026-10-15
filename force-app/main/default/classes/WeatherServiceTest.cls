/**
 * Tests for the WeatherService REST resource (GET /weather-service?city=...), with a mocked OpenWeatherMap.
 * Also guards the security fix: the API key must come from the named credential, never from the URL.
 */
@IsTest
private class WeatherServiceTest {
    private class OpenWeatherMock implements HttpCalloutMock {
        private final Integer statusCode;
        public HttpRequest lastRequest;

        OpenWeatherMock(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setStatus(statusCode == 200 ? 'OK' : 'Unauthorized');
            response.setBody(statusCode == 200 ? '{"name": "Mumbai", "main": {"temp": 29.5}}' : '{"cod": 401}');
            return response;
        }
    }

    private static void setRequest(String city) {
        RestRequest request = new RestRequest();
        request.requestURI = '/services/apexrest/weather-service';
        request.httpMethod = 'GET';
        if (city != null) {
            request.addParameter('city', city);
        }
        RestContext.request = request;
        RestContext.response = new RestResponse();
    }

    @IsTest
    static void shouldReturnCityAndTemperature_ViaNamedCredential() {
        // Given
        OpenWeatherMock mock = new OpenWeatherMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        setRequest('Mumbai');

        // When
        Test.startTest();
        WeatherService.getWeather();
        Test.stopTest();

        // Then
        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        Assert.areEqual('Mumbai', body.get('city'), 'The city should come from the API response');
        Assert.areEqual(29.5, (Decimal) body.get('temperature'), 'The temperature should come from main.temp');
        Assert.areEqual(
            'callout:OpenWeatherMap/data/2.5/weather?q=Mumbai&units=metric',
            mock.lastRequest.getEndpoint(),
            'The call must go through the OpenWeatherMap named credential'
        );
        Assert.isFalse(mock.lastRequest.getEndpoint().contains('appid'), 'No API key may travel in the URL; the named credential sends it as a header');
    }

    @IsTest
    static void shouldDefaultToDelhi_WhenCityMissing() {
        // Given
        OpenWeatherMock mock = new OpenWeatherMock(200);
        Test.setMock(HttpCalloutMock.class, mock);
        setRequest(null);

        // When
        Test.startTest();
        WeatherService.getWeather();
        Test.stopTest();

        // Then
        Assert.isTrue(mock.lastRequest.getEndpoint().contains('q=Delhi'), 'A missing city should default to Delhi');
    }

    @IsTest
    static void shouldPassThroughStatusAndError_WhenApiFails() {
        // Given
        Test.setMock(HttpCalloutMock.class, new OpenWeatherMock(401));
        setRequest('Mumbai');

        // When
        Test.startTest();
        WeatherService.getWeather();
        Test.stopTest();

        // Then
        Assert.areEqual(401, RestContext.response.statusCode, 'The API status should be passed to the caller');
        Assert.areEqual(
            '{"error":"Failed to fetch weather data: Unauthorized"}',
            RestContext.response.responseBody.toString(),
            'The error body should explain the failure'
        );
    }
}
