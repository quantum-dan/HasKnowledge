import "dart:async";
import "dart:convert";
import "dart:html";

const String baseUrl = "http://www.hasknowledge.net/";
const String summariesUrl = "summaries";
const String summaryUrl = "summary/";

Future postSummary(Map summary) async {
  var summaryJson = JSON.encode(summary);
  print(summary);
  print(summaryJson);
  var req = new HttpRequest();
  req.open("POST", baseUrl + summariesUrl);
  req.onReadyStateChange.listen((_) {
    print("Summary POST response: ${req.responseText}");
  });
  req.send(summaryJson);
}

Future handleSummaryPost(InputElement titleField, InputElement topicField,
    InputElement publicAccessField, TextAreaElement contentField) async {
  Map summary = {
    "title": titleField.value,
    "topic": topicField.value,
    "publicAccess": publicAccessField.checked,
    "content": contentField.value,
    "userId": 0,
    "id": 0
  };
  postSummary(summary);
}

Future setupSummaryForm(Element target) async {
  var titleField = new InputElement()
    ..type = "text"
    ..placeholder = "Title";
  var topicField = new InputElement()
    ..type = "text"
    ..placeholder = "Topic";
  var publicAccessContainer = new DivElement()..text = "Public? ";
  var publicAccessField = new InputElement()..type = "checkbox";
  publicAccessContainer.children.add(publicAccessField);
  var contentField = new TextAreaElement()..placeholder = "Summary";
  var contentContainer = new DivElement()..children = [contentField];
  var submitButton = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..onClick.listen((_) {
      handleSummaryPost(
          titleField, topicField, publicAccessField, contentField);
    });
  var submitContainer = new DivElement()..children = [submitButton];
  target.children = [
    titleField,
    topicField,
    publicAccessContainer,
    contentContainer,
    submitContainer
  ];
}

Element summaryToHtml(Map summary) {
  var container = new LIElement()
    ..text =
        "${summary['title']} (${summary['topic']}) Public: ${summary['publicAccess']}";
  var contents = new DivElement()..text = summary["content"];
  var expandToggle = new InputElement()
    ..type = "button"
    ..value = "Expand";
  void toggleContents(bool expand) {
    if (expand) {
      container.children.add(contents);
      expandToggle.value = "Collapse";
      expandToggle.onClick.listen((_) {
        toggleContents(false);
      });
    } else {
      container.children.remove(contents);
      expandToggle.value = "Expand";
      expandToggle.onClick.listen((_) {
        toggleContents(true);
      });
    }
  }

  expandToggle.onClick.listen((_) {
    toggleContents(true);
  });
  container.children.add(expandToggle);
  return container;
}

Future loadSummaries(Element target) async {
  var req = new HttpRequest();
  req.onReadyStateChange.listen((_) {
    if (req.readyState == 4) {
      print(req.responseText);
      List<Map> summariesJson = JSON.decode(req.responseText);
      List<Element> summaries = summariesJson.map(summaryToHtml).toList();
      Element summariesList = new UListElement()..children = summaries;
      target.children = [summariesList];
    }
  });
  req.open("GET", baseUrl + summariesUrl);
  req.send();
}

void runSummaries(Element target) {
    Element container = new DivElement();
    Element summariesElem = new DivElement();
    Element loadButton = new InputElement()
        ..type = "button"
        ..value = "Load Summaries"
        ..onClick.listen((_) {loadSummaries(summariesElem);});
    Element summaryForm = new DivElement();
    setupSummaryForm(summaryForm);
    container.children = [loadButton, summariesElem, summaryForm];
    target.children = [container];
}
