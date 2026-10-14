public class JSONResponseParser {
    @InvocableMethod(
        label='Parse LLM JSON Response'
        description='Parses JSON response from LLM and returns formatted HTML'
    )
    public static List<ParsedResponse> parseJSONResponse(
        List<Request> requests
    ) {
        List<ParsedResponse> responses = new List<ParsedResponse>();

        for (Request req : requests) {
            ParsedResponse resp = new ParsedResponse();

            try {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
                    req.jsonResponse
                );
                Map<String, Object> responseMap = (Map<String, Object>) jsonMap.get(
                    'response'
                );

                String text = (String) responseMap.get('text');
                resp.formattedText = text != null ? formatText(text) : '';

                List<Object> sources = (List<Object>) responseMap.get('source');
                resp.formattedSources = formatSources(sources);

            } catch (Exception e) {
                resp.formattedText =
                    '<p style="color:#c23934;font-size:13px;">&#9888; Error parsing response: ' +
                    e.getMessage() +
                    '</p>';
                resp.formattedSources = '';
            }

            responses.add(resp);
        }

        return responses;
    }

    // Public so AgentResponseFormatter can reuse the same markdown -> HTML rendering.
    public static String formatText(String text) {
        // Normalise escaped newlines
        text = text.replace('\\n', '\n');

        // **bold** and *italic* (process before splitting into lines)
        text = text.replaceAll(
            '\\*\\*([^*]+)\\*\\*',
            '<strong style="font-weight:600;color:#181818;">$1</strong>'
        );
        text = text.replaceAll('\\*([^*]+)\\*', '<em>$1</em>');

        // Process line by line to build lists properly
        List<String> lines = text.split('\n');
        List<String> out = new List<String>();
        Boolean inBullet = false;
        Boolean inNumbered = false;

        for (String line : lines) {
            String trimmed = line.trim();

            // Headings (must close any open list first)
            if (trimmed.startsWith('### ')) {
                if (inBullet)   { out.add('</ul>'); inBullet   = false; }
                if (inNumbered) { out.add('</ol>'); inNumbered = false; }
                out.add('<p style="font-size:14px;font-weight:700;color:#032D60;margin:16px 0 4px 0;">' + trimmed.substring(4) + '</p>');

            } else if (trimmed.startsWith('## ')) {
                if (inBullet)   { out.add('</ul>'); inBullet   = false; }
                if (inNumbered) { out.add('</ol>'); inNumbered = false; }
                out.add('<p style="font-size:16px;font-weight:700;color:#032D60;margin:20px 0 6px 0;padding-bottom:4px;border-bottom:1px solid #E5E5E5;">' + trimmed.substring(3) + '</p>');

            } else if (trimmed.startsWith('# ')) {
                if (inBullet)   { out.add('</ul>'); inBullet   = false; }
                if (inNumbered) { out.add('</ol>'); inNumbered = false; }
                out.add('<p style="font-size:18px;font-weight:700;color:#032D60;margin:20px 0 8px 0;">' + trimmed.substring(2) + '</p>');

            } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
                if (!inBullet) {
                    if (inNumbered) { out.add('</ol>'); inNumbered = false; }
                    out.add('<ul style="margin:8px 0;padding-left:22px;line-height:1.9;color:#181818;">');
                    inBullet = true;
                }
                out.add('<li style="margin-bottom:5px;">' + trimmed.substring(2) + '</li>');

            } else if (trimmed.length() > 2 && trimmed.charAt(0) >= 48 && trimmed.charAt(0) <= 57 && trimmed.contains('. ')) {
                // Numbered list: starts with a digit and contains ". "
                Integer dotIdx = trimmed.indexOf('. ');
                String itemContent = dotIdx >= 0 ? trimmed.substring(dotIdx + 2) : trimmed;
                if (!inNumbered) {
                    if (inBullet) { out.add('</ul>'); inBullet = false; }
                    out.add('<ol style="margin:8px 0;padding-left:22px;line-height:1.9;color:#181818;">');
                    inNumbered = true;
                }
                out.add('<li style="margin-bottom:5px;">' + itemContent + '</li>');

            } else {
                if (inBullet)   { out.add('</ul>');  inBullet   = false; }
                if (inNumbered) { out.add('</ol>');  inNumbered = false; }

                if (String.isBlank(trimmed)) {
                    out.add('<br/>');
                } else {
                    out.add('<p style="margin:6px 0;line-height:1.8;color:#181818;">' + trimmed + '</p>');
                }
            }
        }

        if (inBullet)   out.add('</ul>');
        if (inNumbered) out.add('</ol>');

        return String.join(out, '');
    }

    private static String formatSources(List<Object> sources) {
        if (sources == null || sources.isEmpty()) {
            return '<p style="color:#706E6B;font-style:italic;font-size:13px;">No sources available</p>';
        }

        List<String> cards = new List<String>();
        Integer idx = 1;

        for (Object sourceObj : sources) {
            Map<String, Object> sourceMap = (Map<String, Object>) sourceObj;
            String url = (String) sourceMap.get('source_id');
            if (url == null) continue;

            String domain = extractDomain(url);
            cards.add(
                '<div style="display:flex;align-items:flex-start;margin-bottom:10px;' +
                'padding:10px 14px;background:#F3F3F3;border-radius:6px;' +
                'border-left:3px solid #0176D3;">' +

                '<span style="font-size:11px;font-weight:700;color:#FFFFFF;' +
                'background:#0176D3;border-radius:50%;min-width:20px;height:20px;' +
                'display:inline-flex;align-items:center;justify-content:center;' +
                'margin-right:10px;margin-top:1px;flex-shrink:0;">' +
                String.valueOf(idx) +
                '</span>' +

                '<div style="overflow:hidden;">' +
                '<div style="font-size:13px;font-weight:600;color:#181818;margin-bottom:2px;">' +
                domain +
                '</div>' +
                '<a href="' + url + '" target="_blank" ' +
                'style="font-size:11px;color:#0176D3;text-decoration:none;' +
                'word-break:break-all;">' +
                url +
                '</a>' +
                '</div></div>'
            );
            idx++;
        }

        return cards.isEmpty()
            ? '<p style="color:#706E6B;font-style:italic;font-size:13px;">No sources available</p>'
            : String.join(cards, '');
    }

    private static String extractDomain(String url) {
        try {
            String d = url.replaceAll('^https?://', '');
            Integer slash = d.indexOf('/');
            if (slash > 0) d = d.substring(0, slash);
            return d.replaceAll('^www\\.', '');
        } catch (Exception e) {
            return url;
        }
    }

    public class Request {
        @InvocableVariable(required=true label='JSON Response')
        public String jsonResponse;
    }

    public class ParsedResponse {
        @InvocableVariable
        public String formattedText;

        @InvocableVariable
        public String formattedSources;
    }
}