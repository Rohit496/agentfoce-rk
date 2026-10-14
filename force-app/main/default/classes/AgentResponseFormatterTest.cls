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

        System.assertEquals(
            'Here are some accounts: Edge Communications, GenePoint.',
            out[0].plainText,
            'Envelope should be unwrapped to its value'
        );
        System.assert(
            !out[0].formattedResponse.contains('"type"'),
            'Formatted output must not leak the JSON envelope'
        );
        System.assert(
            out[0].formattedResponse.contains('Edge Communications'),
            'Formatted output should retain the agent text'
        );
    }

    @isTest
    static void rendersNewlinesAsMarkup() {
        String raw = '{"type":"Text","value":"Line one.\\n\\nLine two."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assert(
            out[0].formattedResponse.contains('Line one.'),
            'First line should survive formatting'
        );
        System.assert(
            out[0].formattedResponse.contains('Line two.'),
            'Second line should survive formatting'
        );
        System.assert(
            !out[0].formattedResponse.contains('\\n'),
            'Escaped newlines should be converted, not shown literally'
        );
    }

    @isTest
    static void formatsMarkdownLists() {
        String raw = '{"type":"Text","value":"Accounts:\\n- Edge Communications\\n- GenePoint"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assert(
            out[0].formattedResponse.contains('<ul'),
            'Markdown bullets should render as a list'
        );
        System.assert(
            out[0].formattedResponse.contains('<li'),
            'Bullet items should render as list items'
        );
    }

    @isTest
    static void passesThroughPlainText() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(
            'Just a plain answer.'
        );
        Test.stopTest();

        System.assertEquals(
            'Just a plain answer.',
            out[0].plainText,
            'Non-JSON input should pass through untouched'
        );
    }

    @isTest
    static void fallsBackOnMalformedJson() {
        String raw = '{"type":"Text","value":';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assertEquals(
            raw,
            out[0].plainText,
            'Malformed JSON should degrade to the raw string, not throw'
        );
    }

    @isTest
    static void handlesEnvelopeArray() {
        String raw = '[{"type":"Text","value":"First."},{"type":"Text","value":"Second."}]';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assert(
            out[0].plainText.contains('First.') &&
            out[0].plainText.contains('Second.'),
            'All envelopes in an array should be concatenated'
        );
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

        System.assertEquals(true, out[0].hasRows, 'A list should be detected');
        System.assertEquals(3, out[0].rowCount, 'Three accounts should become rows');
        System.assertEquals('Edge Communications', out[0].rows[0].name);
        System.assertEquals(1, out[0].rows[0].position, 'Rows should be numbered from 1');
        System.assertEquals('GenePoint', out[0].rows[2].name);
        System.assertEquals(
            'Here are all accounts:',
            out[0].introText,
            'Lead-in line should be captured as intro, not a row'
        );
        System.assert(
            out[0].outroText.contains('Would you like details'),
            'Trailing question should be captured as outro, not a row'
        );
    }

    @isTest
    static void buildsRowsFromMarkdownBullets() {
        String raw =
            '{"type":"Text","value":"Accounts:\\n- **Edge Communications**\\n' +
            '- **GenePoint**\\n- **sForce**"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assertEquals(3, out[0].rowCount, 'Bulleted items should become rows');
        System.assertEquals(
            'Edge Communications',
            out[0].rows[0].name,
            'Bullet markers and bold markup should be stripped'
        );
    }

    @isTest
    static void splitsNameAndDetail() {
        String raw =
            '{"type":"Text","value":"Accounts:\\n- Edge Communications - Texas\\n' +
            '- GenePoint - California"}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assertEquals('Edge Communications', out[0].rows[0].name);
        System.assertEquals(
            'Texas',
            out[0].rows[0].detail,
            'Trailing detail should populate the second column'
        );
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

        System.assertEquals(
            true,
            out[0].hasRows,
            'A list with no lead-in line must still be detected'
        );
        System.assertEquals(6, out[0].rowCount, 'All six accounts should become rows');
        System.assertEquals('Edge Communications', out[0].rows[0].name);
        System.assertEquals(
            'Pyramid Construction Inc.',
            out[0].rows[5].name,
            'A name ending in "." is still an item, not prose'
        );
        System.assert(
            out[0].outroText.contains('Let me know'),
            'The closing sentence should be outro, not a row'
        );
        System.assertEquals(
            6,
            out[0].recordRows.size(),
            'Data Table records should mirror the parsed rows'
        );
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
        System.assert(html.contains('<table'), 'A table element should be rendered');
        System.assert(html.contains('Name'), 'Header row should be present');
        System.assert(
            html.contains('Edge Communications'),
            'Each parsed row should appear in the table'
        );
        System.assert(html.contains('sForce'), 'Last row should appear');
        System.assert(html.contains('3 results'), 'Row count should be shown');
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
        System.assert(
            !html.contains('<script>'),
            'Raw script tags must not survive into the rendered table'
        );
        System.assert(
            html.contains('&lt;script&gt;'),
            'Angle brackets should be escaped'
        );
        System.assert(
            html.contains('Safe &amp; Sound'),
            'Ampersands should be escaped'
        );
    }

    @isTest
    static void producesNoTableHtmlForProse() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(
            '{"type":"Text","value":"The account was updated successfully."}'
        );
        Test.stopTest();

        System.assertEquals(
            '',
            out[0].tableHtml,
            'Prose replies should produce no table markup'
        );
    }

    @isTest
    static void treatsShortReplyAsProseNotTable() {
        String raw = '{"type":"Text","value":"The account was updated successfully."}';

        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run(raw);
        Test.stopTest();

        System.assertEquals(
            false,
            out[0].hasRows,
            'A single sentence should not be rendered as a table'
        );
        System.assertEquals(0, out[0].rowCount);
    }

    @isTest
    static void handlesBlankResponse() {
        Test.startTest();
        List<AgentResponseFormatter.FormattedResponse> out = run('');
        Test.stopTest();

        System.assertEquals('', out[0].plainText);
        System.assert(
            out[0].formattedResponse.contains('did not return'),
            'Blank input should produce a friendly message'
        );
    }
}