/**
 * Tests for WeatherDemo, using an HttpCalloutMock instead of the real Weather_NC named credential.
 */
@IsTest
private class WeatherDemoTest {
    private class WeatherMock implements HttpCalloutMock {
        public HttpRequest lastRequest;
        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"location":{"name":"San Francisco"},"current":{"temp_c":18}}');
            return response;
        }
    }

    @IsTest
    static void shouldReturnResponseBody_AndUrlEncodeCity() {
        // Given
        WeatherMock mock = new WeatherMock();
        Test.setMock(HttpCalloutMock.class, mock);

        // When
        Test.startTest();
        String body = WeatherDemo.getWeather('San Francisco');
        Test.stopTest();

        // Then
        Assert.areEqual('{"location":{"name":"San Francisco"},"current":{"temp_c":18}}', body, 'The raw API body should be returned');
        Assert.areEqual('GET', mock.lastRequest.getMethod(), 'The weather API should be called with GET');
        Assert.areEqual(
            'callout:Weather_NC/current.json?q=San+Francisco',
            mock.lastRequest.getEndpoint(),
            'The city should be URL-encoded into the named-credential endpoint'
        );
    }
}
