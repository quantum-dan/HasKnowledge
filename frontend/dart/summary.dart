import "dart:async";
import "dart:convert";
import "dart:html";
import "generic.dart";

const String baseUrl = "/";
const String summariesUrl = "summaries";
const String summaryUrl = "summary/";

Future postSummary(Map summary) async {
  String summaryJson = JSON.encode(summary);
  print(summary);
  print(summaryJson);
  HttpRequest req = new HttpRequest();
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
  titleField.value = "";
  topicField.value = "";
  publicAccessField.checked = false;
  contentField.value = "";
}

Future setupSummaryForm(Element target) async {
  ParagraphElement description = new ParagraphElement()
    ..text = "Create a Summary";
  InputElement titleField = new InputElement()
    ..type = "text"
    ..classes.add("summaryTitleField")
    ..placeholder = "Title";
  InputElement topicField = new InputElement()
    ..type = "text"
    ..classes.add("summaryTopicField")
    ..placeholder = "Topic";
  DivElement publicAccessContainer = new DivElement()
    ..text = "Public? "
    ..classes.add("summaryPublicContainer");
  InputElement publicAccessField = new InputElement()
    ..type = "checkbox"
    ..classes.add("summaryPublicField");
  publicAccessContainer.children.add(publicAccessField);
  TextAreaElement contentField = new TextAreaElement()
    ..placeholder = "Summary"
    ..rows = 20
    ..classes.add("summaryContentField");
  DivElement contentContainer = new DivElement()
    ..children = [contentField]
    ..classes.add("summaryContentFieldContainer");
  InputElement submitButton = new InputElement()
    ..type = "button"
    ..value = "Submit"
    ..classes.add("summarySubmitInput")
    ..classes.add("submit")
    ..onClick.listen((_) {
      handleSummaryPost(
          titleField, topicField, publicAccessField, contentField);
    });
  DivElement submitContainer = new DivElement()
    ..children = [submitButton]
    ..classes.add("summarySubmitContainer");
  target.children = [
    description,
    titleField,
    topicField,
    publicAccessContainer,
    contentContainer,
    submitContainer
  ];
}

Element summaryToHtml(Map summary) {
  LIElement container = new LIElement()
    ..classes.add("summaryListing")
    ..text = "${summary['title']} (${summary['topic']})";
  DivElement contents = new DivElement()
    ..classes.add("summaryContent")
    ..innerHtml = summary["content"];
  InputElement expandToggle = new InputElement()
    ..type = "button"
    ..classes.add("summaryExpandToggle")
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
  HttpRequest req = new HttpRequest();
  UListElement innerTarget = new UListElement()..classes.add("summaries");
  UListElement filterList = new UListElement()..classes.add("filters");
  target.children = [filterList, innerTarget];
  req.onReadyStateChange.listen((_) {
    if (req.readyState == 4) {
      print(req.responseText);
      List<Map> summariesJson = JSON.decode(req.responseText);
      filterList.children = summariesJson
          .map((summary) => summary["topic"])
          .toSet()
          .map((topic) => new LIElement()
            ..classes.add("filter")
            ..children.add(new InputElement()
              ..type = "button"
              ..value = topic
              ..onClick.listen((_) {
                loadFilteredSummaries(innerTarget, topic);
              })))
          .toList();
      List<Element> summaries = summariesJson.map(summaryToHtml).toList();
      innerTarget.children = summaries;
    }
  });
  req.open("GET", baseUrl + summariesUrl);
  req.send();
}

Future loadFilteredSummaries(Element target, String topic) async {
  target.children =
      (await getFiltered(Routes.summaries(topic))).map(summaryToHtml).toList();
}

Future runSummaries(Element target) async {
  Element container = new DivElement();
  Element summariesElem = new DivElement();
  Element loadButton = new InputElement()
    ..type = "button"
    ..value = "Load Summaries"
    ..classes.add("loadSummaries")
    ..onClick.listen((_) {
      loadSummaries(summariesElem);
    });
  bool loggedIn = await isLoggedIn();
  Element summaryForm = new DivElement()..classes.add("summaryForm");
  if (loggedIn) {
    setupSummaryForm(summaryForm);
  }
  container.children = loggedIn
      ? [loadButton, summariesElem, summaryForm]
      : [loadButton, summariesElem];
  target.children = [container];
}
