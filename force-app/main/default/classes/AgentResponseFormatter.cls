/**
 * Formats the raw output of the `generateAiAgentResponse` Flow action into
 * display-ready HTML.
 *
 * Agentforce returns the agent reply wrapped in an envelope rather than as
 * plain text, e.g. {"type":"Text","value":"Here are some accounts...\n\n..."}.
 * Rendering that verbatim in a Screen Flow shows the JSON to the end user.
 *
 * This action unwraps the envelope and reuses JSONResponseParser.formatText()
 * so agent replies render with the same markdown/bullet styling as the
 * Web_Search flow. Anything unrecognised falls back to the raw string, so a
 * change to the envelope shape degrades to plain text rather than an error.
 */
public class AgentResponseFormatter {
    @InvocableMethod(
        label='Format Agent Response'
        description='Unwraps the Agentforce agent response envelope and returns formatted HTML'
    )
    public static List<FormattedResponse> formatAgentResponse(
        List<Request> requests
    ) {
        List<FormattedResponse> responses = new List<FormattedResponse>();

        for (Request req : requests) {
            FormattedResponse resp = new FormattedResponse();
            String raw = req.agentResponse;

            if (String.isBlank(raw)) {
                resp.formattedResponse = '<p style="color:#706E6B;font-style:italic;font-size:13px;">The agent did not return a response.</p>';
                resp.plainText = '';
                resp.rows = new List<AgentResponseRow>();
                resp.rowCount = 0;
                resp.hasRows = false;
                resp.introText = '';
                resp.outroText = '';
                resp.tableHtml = '';
                resp.recordRows = new List<Agent_Result__c>();
                responses.add(resp);
                continue;
            }

            String text = extractText(raw);
            resp.plainText = text;
            resp.formattedResponse = JSONResponseParser.formatText(text);

            ListParts parts = parseList(text);
            resp.rows = parts.rows;
            resp.rowCount = parts.rows.size();
            resp.hasRows = !parts.rows.isEmpty();
            resp.introText = parts.intro;
            resp.outroText = parts.outro;
            resp.tableHtml = buildTableHtml(parts.rows);
            resp.recordRows = toRecords(parts.rows);

            responses.add(resp);
        }

        return responses;
    }

    // A wrapped sentence rather than a list item.
    private static final Integer LONG_LINE = 80;

    // Record names are short; agent prose is not.
    private static final Integer MAX_ITEM_WORDS = 8;

    /**
     * Renders parsed rows as a styled HTML table for a Display Text field.
     *
     * The standard Flow Data Table component can't bind an Apex-defined
     * collection, so this keeps the table rendering self-contained. The `rows`
     * output is still published for anyone wiring up a real Data Table.
     */
    private static String buildTableHtml(List<AgentResponseRow> rows) {
        if (rows == null || rows.isEmpty()) {
            return '';
        }

        Boolean hasDetail = false;
        for (AgentResponseRow r : rows) {
            if (String.isNotBlank(r.detail)) {
                hasDetail = true;
                break;
            }
        }

        String th =
            'padding:9px 14px;text-align:left;font-size:11px;font-weight:700;' +
            'letter-spacing:0.04em;text-transform:uppercase;color:#514F4D;' +
            'background:#F3F3F3;border-bottom:1px solid #D8DDE6;';

        List<String> html = new List<String>();
        html.add(
            '<div style="border:1px solid #D8DDE6;border-radius:8px;overflow:hidden;margin:12px 0 4px 0;">'
        );
        html.add(
            '<table style="width:100%;border-collapse:collapse;font-size:14px;color:#181818;">'
        );
        html.add('<thead><tr>');
        html.add('<th style="' + th + 'width:52px;">#</th>');
        html.add('<th style="' + th + '">Name</th>');
        if (hasDetail) {
            html.add('<th style="' + th + '">Details</th>');
        }
        html.add('</tr></thead><tbody>');

        Integer i = 0;
        for (AgentResponseRow r : rows) {
            String bg = Math.mod(i, 2) == 0 ? '#FFFFFF' : '#FAFBFC';
            String td =
                'padding:9px 14px;border-bottom:1px solid #F0F0F0;vertical-align:top;';
            html.add('<tr style="background:' + bg + ';">');
            html.add(
                '<td style="' + td + 'color:#706E6B;">' + r.position + '</td>'
            );
            html.add(
                '<td style="' + td + 'font-weight:600;">' + escapeHtml(r.name) + '</td>'
            );
            if (hasDetail) {
                html.add(
                    '<td style="' + td + 'color:#444444;">' +
                    escapeHtml(r.detail) +
                    '</td>'
                );
            }
            html.add('</tr>');
            i++;
        }

        html.add('</tbody></table></div>');
        html.add(
            '<div style="font-size:11px;color:#706E6B;margin-bottom:4px;">' +
            rows.size() +
            (rows.size() == 1 ? ' result' : ' results') +
            '</div>'
        );
        return String.join(html, '');
    }

    /**
     * Mirrors the parsed rows into in-memory Agent_Result__c records.
     *
     * The standard Flow Data Table can only bind an SObject collection - it
     * does not support Apex-defined types - so this is what feeds it. The
     * records are never inserted; Agent_Result__c exists purely as a display
     * carrier and stores no data.
     */
    private static List<Agent_Result__c> toRecords(List<AgentResponseRow> rows) {
        List<Agent_Result__c> records = new List<Agent_Result__c>();
        if (rows == null) {
            return records;
        }
        for (AgentResponseRow r : rows) {
            records.add(
                new Agent_Result__c(
                    Name = r.name != null && r.name.length() > 80
                        ? r.name.substring(0, 80)
                        : r.name,
                    Detail__c = r.detail,
                    Position__c = r.position
                )
            );
        }
        return records;
    }

    /** Agent text is untrusted input being injected into rich text. */
    private static String escapeHtml(String value) {
        if (String.isBlank(value)) {
            return '';
        }
        return value.replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;');
    }

    private class ListParts {
        List<AgentResponseRow> rows = new List<AgentResponseRow>();
        String intro = '';
        String outro = '';
    }

    /**
     * Recovers a list from the agent's prose so it can be shown in a Data Table.
     *
     * Two shapes occur in practice:
     *   1. Explicit markdown bullets ("- Edge Communications", "1. Edge ...")
     *   2. A lead-in line ending in ":" followed by one item per line, which is
     *      what the agent produces even when asked for bullets.
     *
     * Fewer than two items is treated as prose, not a table.
     */
    private static ListParts parseList(String text) {
        ListParts parts = new ListParts();
        if (String.isBlank(text)) {
            return parts;
        }

        // Classify every line independently first. Deciding line-by-line is
        // what makes this robust: the agent often omits the "Here are all
        // accounts:" lead-in entirely and starts listing straight away, so
        // there is no reliable marker for where a list begins.
        List<String> lines = new List<String>();
        List<Boolean> isItem = new List<Boolean>();

        for (String rawLine : text.replace('\\n', '\n').split('\n')) {
            String line = stripMarkdown(rawLine);
            if (String.isBlank(line)) {
                continue;
            }

            String bullet = stripBullet(line);
            if (bullet != null) {
                lines.add(bullet);
                isItem.add(true);
                continue;
            }

            lines.add(line);
            isItem.add(looksLikeItem(line));
        }

        Integer firstItem = -1;
        Integer lastItem = -1;
        Integer itemCount = 0;
        for (Integer i = 0; i < lines.size(); i++) {
            if (isItem[i]) {
                if (firstItem == -1) {
                    firstItem = i;
                }
                lastItem = i;
                itemCount++;
            }
        }

        // One stray short line is a sentence fragment, not a table.
        if (itemCount < 2) {
            return parts;
        }

        List<String> intro = new List<String>();
        List<String> outro = new List<String>();
        Integer position = 1;

        for (Integer i = 0; i < lines.size(); i++) {
            if (isItem[i]) {
                parts.rows.add(splitDetail(position, lines[i]));
                position++;
            } else if (i < firstItem) {
                intro.add(lines[i]);
            } else if (i > lastItem) {
                outro.add(lines[i]);
            }
            // Prose between items is dropped - it is almost always a stray
            // wrapped fragment, and keeping it would corrupt the table.
        }

        parts.intro = String.join(intro, ' ');
        parts.outro = String.join(outro, ' ');
        return parts;
    }

    /**
     * A line is a list item unless it reads as a sentence.
     *
     * Word count carries most of the weight: record names are short ("United
     * Oil & Gas, UK") while agent prose is not ("Let me know if you need
     * details on any specific account"). Trailing '.' is deliberately not a
     * disqualifier - "Pyramid Construction Inc." is a real account name.
     */
    private static Boolean looksLikeItem(String line) {
        if (line.length() > LONG_LINE || line.endsWith('?') || line.endsWith(':')) {
            return false;
        }
        Integer words = line.split('\\s+').size();
        return words <= MAX_ITEM_WORDS;
    }

    /** Returns the item text if the line is a bullet or numbered entry, else null. */
    private static String stripBullet(String line) {
        Matcher m = Pattern.compile('^(?:[-*\\u2022]\\s+|\\d+[.)]\\s+)(.*)$')
            .matcher(line);
        return m.matches() ? m.group(1).trim() : null;
    }

    /** Splits "Name - detail" / "Name: detail" into two columns when present. */
    private static AgentResponseRow splitDetail(Integer position, String raw) {
        Matcher m = Pattern.compile('^(.+?)\\s+(?:\\u2014|\\u2013|-|:)\\s+(.+)$')
            .matcher(raw);
        return m.matches()
            ? new AgentResponseRow(position, m.group(1).trim(), m.group(2).trim())
            : new AgentResponseRow(position, raw, '');
    }

    private static String stripMarkdown(String line) {
        if (line == null) {
            return '';
        }
        return line.replaceAll('\\*\\*(.+?)\\*\\*', '$1')
            .replaceAll('^#{1,6}\\s+', '')
            .trim();
    }

    /**
     * Pulls the human-readable text out of whatever the action returned.
     * Handles the {"type":..,"value":..} envelope, a bare JSON array of those
     * envelopes, and plain (non-JSON) text.
     */
    private static String extractText(String raw) {
        String trimmed = raw.trim();

        // Not JSON-shaped - already plain text.
        if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
            return raw;
        }

        try {
            Object parsed = JSON.deserializeUntyped(trimmed);

            if (parsed instanceof List<Object>) {
                List<String> parts = new List<String>();
                for (Object item : (List<Object>) parsed) {
                    String part = valueFromMap(item);
                    if (String.isNotBlank(part)) {
                        parts.add(part);
                    }
                }
                return parts.isEmpty() ? raw : String.join(parts, '\n\n');
            }

            String single = valueFromMap(parsed);
            return String.isNotBlank(single) ? single : raw;
        } catch (Exception e) {
            // Malformed or unexpected JSON - show what we got rather than an error.
            return raw;
        }
    }

    /** Reads the text-bearing key from one envelope map. */
    private static String valueFromMap(Object item) {
        if (!(item instanceof Map<String, Object>)) {
            return null;
        }
        Map<String, Object> m = (Map<String, Object>) item;

        // 'value' is what generateAiAgentResponse uses today; the others are
        // defensive against neighbouring Agentforce payload shapes.
        for (String key : new List<String>{ 'value', 'text', 'message' }) {
            Object v = m.get(key);
            if (v instanceof String && String.isNotBlank((String) v)) {
                return (String) v;
            }
        }
        return null;
    }

    public class Request {
        @InvocableVariable(required=true label='Agent Response')
        public String agentResponse;
    }

    public class FormattedResponse {
        @InvocableVariable(label='Formatted Response (HTML)')
        public String formattedResponse;

        @InvocableVariable(label='Plain Text')
        public String plainText;

        @InvocableVariable(label='Table Rows')
        public List<AgentResponseRow> rows;

        @InvocableVariable(label='Row Count')
        public Integer rowCount;

        @InvocableVariable(label='Has Rows')
        public Boolean hasRows;

        @InvocableVariable(label='Intro Text')
        public String introText;

        @InvocableVariable(label='Outro Text')
        public String outroText;

        @InvocableVariable(label='Table HTML')
        public String tableHtml;

        @InvocableVariable(label='Table Records')
        public List<Agent_Result__c> recordRows;
    }
}