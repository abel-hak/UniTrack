const SCRIPT_BLOCK_RE =
  /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi;
const HTML_TAG_RE = /<[^>]*>/g;

export function stripHtml(input: string): string {
  return input.replace(SCRIPT_BLOCK_RE, "").replace(HTML_TAG_RE, "").trim();
}
