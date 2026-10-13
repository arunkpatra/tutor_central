/** The events' kinds in words (plan decision 16; the app's ActivityKind). The record's own rows (closes, notes, fees,
 *  material made again) carry their words from SQL (0047's admin_activity). */
function screenWords(screen: string): string {
  const plain = screen.replace(/_/g, " ");
  return plain.charAt(0).toUpperCase() + plain.slice(1);
}

export function activityWords(kind: string, screen: string | null): string {
  switch (kind) {
    case "app_opened":
      return screen ? `Opened the app · ${screenWords(screen)}` : "Opened the app";
    case "signed_in":
      return "Signed in";
    case "signed_out":
      return "Signed out";
    case "tab_opened":
      return screen ? `Opened ${screenWords(screen)}` : "Opened a tab";
    case "link_opened":
      return screen ? `Opened a link · ${screenWords(screen)}` : "Opened a link";
    default:
      return kind.replace(/_/g, " ");
  }
}
