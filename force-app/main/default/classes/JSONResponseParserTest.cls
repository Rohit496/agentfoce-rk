@isTest
private class JSONResponseParserTest {
    private static List<JSONResponseParser.ParsedResponse> run(String raw) {
        JSONResponseParser.Request req = new JSONResponseParser.Request();
        req.jsonResponse = raw;
        return JSONResponseParser.parseJSONResponse(
            new List<JSONResponseParser.Request>{ req }
        );
    }

    @isTest
    static void parsesTextAndSources() {
        String raw =
            '{"response":{"text":"Executive summary for Dell.",' +
            '"source":[{"source_id":"https://www.dell.com/en-us"},' +
            '{"source_id":"https://finance.yahoo.com/quote/DELL/"}]}}';

        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].formattedText.contains('Executive summary for Dell.'), 'Response text should be rendered');
        Assert.isTrue(out[0].formattedSources.contains('dell.com'), 'Source domain should be extracted and shown');
        Assert.isTrue(out[0].formattedSources.contains('finance.yahoo.com'), 'All sources should be rendered');
    }

    @isTest
    static void rendersMarkdownStructures() {
        String raw =
            '{"response":{"text":"# Title\\n## Section\\n### Sub\\n' +
            'Intro **bold** and *italic*.\\n- bullet one\\n- bullet two\\n' +
            '1. first\\n2. second\\n\\nTail.","source":[]}}';

        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run(raw);
        Test.stopTest();

        String html = out[0].formattedText;
        Assert.isTrue(html.contains('Title'), 'H1 should render');
        Assert.isTrue(html.contains('Section'), 'H2 should render');
        Assert.isTrue(html.contains('Sub'), 'H3 should render');
        Assert.isTrue(html.contains('<strong'), 'Bold should render');
        Assert.isTrue(html.contains('<em>'), 'Italic should render');
        Assert.isTrue(html.contains('<ul'), 'Bulleted list should render');
        Assert.isTrue(html.contains('<ol'), 'Numbered list should render');
    }

    @isTest
    static void showsMessageWhenNoSources() {
        String raw = '{"response":{"text":"No citations here.","source":[]}}';

        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].formattedSources.contains('No sources available'), 'Empty source array should produce the empty-state message');
    }

    @isTest
    static void skipsSourcesMissingAnId() {
        String raw =
            '{"response":{"text":"Partial sources.",' +
            '"source":[{"source_id":"https://example.com/docs"},{"other":"x"}]}}';

        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].formattedSources.contains('example.com'), 'Valid source should still render');
    }

    @isTest
    static void reportsParseErrors() {
        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run('not json at all');
        Test.stopTest();

        Assert.isTrue(out[0].formattedText.contains('Error parsing response'), 'Malformed input should surface a readable error, not throw');
        Assert.areEqual('', out[0].formattedSources, 'Sources should be empty when parsing fails');
    }

    @isTest
    static void handlesMissingTextField() {
        Test.startTest();
        List<JSONResponseParser.ParsedResponse> out = run(
            '{"response":{"source":[]}}'
        );
        Test.stopTest();

        Assert.areEqual('', out[0].formattedText, 'Missing text should yield an empty string');
    }
}