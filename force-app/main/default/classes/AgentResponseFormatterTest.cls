@isTest
private class AgentResponseFormatterTest {
    private static List<AgentResponseFormatter.FormattedResponse> run(
        String raw
    ) {
        AgentResponseFormatter.Request req = new AgentResponseFormatter.Request();
        req.agentResponse = raw;
        return AgentResponseFormatter.formatAgentResponse(
            new List<AgentResponseFormatter.Request>{ req }
        );
    }

    @isTest
    static void unwrapsTextEnvelope() {
        // The shape generateAiAgentResponse actually returns.
        String raw = '{"type":"Text","value":"Here are some accounts: Edge Communications, GenePoint."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.areEqual('Here are some accounts: Edge Communications, GenePoint.', out[0].plainText, 'Envelope should be unwrapped to its value');
        Assert.isFalse(out[0].formattedResponse.contains('"type"'), 'Formatted output must not leak the JSON envelope');
        Assert.isTrue(out[0].formattedResponse.contains('Edge Communications'), 'Formatted output should retain the agent text');
    }

    @isTest
    static void rendersNewlinesAsMarkup() {
        String raw = '{"type":"Text","value":"Line one.\\n\\nLine two."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].formattedResponse.contains('Line one.'), 'First line should survive formatting');
        Assert.isTrue(out[0].formattedResponse.contains('Line two.'), 'Second line should survive formatting');
        Assert.isFalse(out[0].formattedResponse.contains('\\n'), 'Escaped newlines should be converted, not shown literally');
    }

    @isTest
    static void formatsMarkdownLists() {
        String raw = '{"type":"Text","value":"Accounts:\\n- Edge Communications\\n- GenePoint"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].formattedResponse.contains('<ul'), 'Markdown bullets should render as a list');
        Assert.isTrue(out[0].formattedResponse.contains('<li'), 'Bullet items should render as list items');
    }

    @isTest
    static void passesThroughPlainText() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(
            'Just a plain answer.'
        );
        Test.stopTest();

        Assert.areEqual('Just a plain answer.', out[0].plainText, 'Non-JSON input should pass through untouched');
    }

    @isTest
    static void fallsBackOnMalformedJson() {
        String raw = '{"type":"Text","value":';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.areEqual(raw, out[0].plainText, 'Malformed JSON should degrade to the raw string, not throw');
    }

    @isTest
    static void handlesEnvelopeArray() {
        String raw = '[{"type":"Text","value":"First."},{"type":"Text","value":"Second."}]';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].plainText.contains('First.') &&
            out[0].plainText.contains('Second.'), 'All envelopes in an array should be concatenated');
    }

    @isTest
    static void buildsRowsFromImplicitList() {
        // The shape the agent actually returns: lead-in line, then one per line.
        String raw =
            '{"type":"Text","value":"Here are all accounts:\\n' +
            'Edge Communications\\nDickenson plc\\nGenePoint\\n' +
            'Would you like details on any specific account?"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].hasRows, 'A list should be detected');
        Assert.areEqual(3, out[0].rowCount, 'Three accounts should become rows');
        Assert.areEqual('Edge Communications', out[0].rows[0].name, 'Expected out[0].rows[0].name to equal \'Edge Communications\'');
        Assert.areEqual(1, out[0].rows[0].position, 'Rows should be numbered from 1');
        Assert.areEqual('GenePoint', out[0].rows[2].name, 'Expected out[0].rows[2].name to equal \'GenePoint\'');
        Assert.areEqual('Here are all accounts:', out[0].introText, 'Lead-in line should be captured as intro, not a row');
        Assert.isTrue(out[0].outroText.contains('Would you like details'), 'Trailing question should be captured as outro, not a row');
    }

    @isTest
    static void buildsRowsFromMarkdownBullets() {
        String raw =
            '{"type":"Text","value":"Accounts:\\n- **Edge Communications**\\n' +
            '- **GenePoint**\\n- **sForce**"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.areEqual(3, out[0].rowCount, 'Bulleted items should become rows');
        Assert.areEqual('Edge Communications', out[0].rows[0].name, 'Bullet markers and bold markup should be stripped');
    }

    @isTest
    static void splitsNameAndDetail() {
        String raw =
            '{"type":"Text","value":"Accounts:\\n- Edge Communications - Texas\\n' +
            '- GenePoint - California"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.areEqual('Edge Communications', out[0].rows[0].name, 'Expected out[0].rows[0].name to equal \'Edge Communications\'');
        Assert.areEqual('Texas', out[0].rows[0].detail, 'Trailing detail should populate the second column');
    }

    @isTest
    static void buildsRowsWithNoLeadInLine() {
        // Verbatim shape from a real run: the agent starts listing immediately,
        // with no "Here are all accounts:" lead-in to key off.
        String raw =
            '{"type":"Text","value":"Edge Communications\\nDickenson plc\\n' +
            'United Oil & Gas, UK\\nBurlington Textiles Corp of America\\n' +
            'Sample Account for Entitlements\\nPyramid Construction Inc.\\n' +
            'Let me know if you need details on any specific account or want to filter this list."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isTrue(out[0].hasRows, 'A list with no lead-in line must still be detected');
        Assert.areEqual(6, out[0].rowCount, 'All six accounts should become rows');
        Assert.areEqual('Edge Communications', out[0].rows[0].name, 'Expected out[0].rows[0].name to equal \'Edge Communications\'');
        Assert.areEqual('Pyramid Construction Inc.', out[0].rows[5].name, 'A name ending in "." is still an item, not prose');
        Assert.isTrue(out[0].outroText.contains('Let me know'), 'The closing sentence should be outro, not a row');
        Assert.areEqual(6, out[0].recordRows.size(), 'Data Table records should mirror the parsed rows');
    }

    @isTest
    static void rendersTableHtmlForLists() {
        String raw =
            '{"type":"Text","value":"Here are all accounts:\\n' +
            'Edge Communications\\nGenePoint\\nsForce"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        String html = out[0].tableHtml;
        Assert.isTrue(html.contains('<table'), 'A table element should be rendered');
        Assert.isTrue(html.contains('Name'), 'Header row should be present');
        Assert.isTrue(html.contains('Edge Communications'), 'Each parsed row should appear in the table');
        Assert.isTrue(html.contains('sForce'), 'Last row should appear');
        Assert.isTrue(html.contains('3 results'), 'Row count should be shown');
    }

    @isTest
    static void escapesHtmlInAgentText() {
        // Agent text is untrusted input being injected into a rich text field.
        String raw =
            '{"type":"Text","value":"Accounts:\\n- <script>alert(1)</script>\\n- Safe & Sound"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        String html = out[0].tableHtml;
        Assert.isFalse(html.contains('<script>'), 'Raw script tags must not survive into the rendered table');
        Assert.isTrue(html.contains('&lt;script&gt;'), 'Angle brackets should be escaped');
        Assert.isTrue(html.contains('Safe &amp; Sound'), 'Ampersands should be escaped');
    }

    @isTest
    static void producesNoTableHtmlForProse() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(
            '{"type":"Text","value":"The account was updated successfully."}'
        );
        Test.stopTest();

        Assert.areEqual('', out[0].tableHtml, 'Prose replies should produce no table markup');
    }

    @isTest
    static void treatsShortReplyAsProseNotTable() {
        String raw = '{"type":"Text","value":"The account was updated successfully."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        Assert.isFalse(out[0].hasRows, 'A single sentence should not be rendered as a table');
        Assert.areEqual(0, out[0].rowCount, 'Expected out[0].rowCount to equal 0');
    }

    @isTest
    static void handlesBlankResponse() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run('');
        Test.stopTest();

        Assert.areEqual('', out[0].plainText, 'Expected out[0].plainText to equal \'\'');
        Assert.isTrue(out[0].formattedResponse.contains('did not return'), 'Blank input should produce a friendly message');
    }
}