class EmailHandler {
  static String replacePlaceholders(String template, String replacement) {
    return template.replaceAll("|CONTENT|",
        "<p>${replacement.replaceAll("\n", "<br>").replaceAll("    ", "&ensp;&ensp;").replaceAll("\t", "&ensp;&ensp;")}<p>");
  }
}
