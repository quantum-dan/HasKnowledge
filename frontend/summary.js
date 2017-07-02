// Functions for working with summaries

function updateSummaryList(handler) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "/summaries", true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
            console.log(xhr.responseText);
            var summaries = JSON.parse(xhr.responseText);
            handler(summaries);
        }
    };
    xhr.send();
}

function summariesHandlerXhr(xhr, listId) {
    if (xhr.readyState == XMLHttpRequest.DONE) {
        var rt = xhr.responseText;
        var summaries = JSON.parse(rt);
        summariesHandler(summaries, listId);
    }
}

var summaryContents = [];
var expandString = "(Expand)";

function expandSummary(object, id) {
    if (object.innerHTML == expandString) {
        object.innerHTML = summaryContents[id];
    } else {
        object.innerHTML = expandString;
    }
}

function summariesToList(summaries, listId) {
    var html = "";
    summaries.forEach(function(summary, index) {
        summaryContents.push(summary.content);
        var innerContent = "<li>" + summary.title + " (" + summary.topic + ") <p onclick=expandSummary(this," + index.toString() + ")>" + expandString + "</p></li>";
        html += innerContent;
    });
    document.getElementById(listId).innerHTML = html;
}

function summariesHandler(listId) {
    return function(summaries) { summariesToList(summaries, listId); };
}

function submitSummary(titleId, topicId, publicId, contentId) {
    var summary = {
        title: document.getElementById(titleId).value,
        topic: document.getElementById(topicId).value,
        publicAccess: document.getElementById(publicId).checked,
        content: document.getElementById(contentId).value,
        userId: 0
    };
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/summaries", true);
    xhr.onreadystatechange = setupSummaries;
    xhr.send(JSON.stringify(summary));
    [titleId, topicId, contentId].forEach(function(id) {
        document.getElementById(id).value = "";
    });
    document.getElementById(publicId).checked = false;
}

function setupSummaries() {
    var html = "<ul style='text-align:left' id='summaries'></ul>";
    var formHtml = "<div>Create Summary: <input type=text placeholder='Title' id='summaryTitle' />" +
        "<input type=text placeholder='Topic' id='summaryTopic' />" +
        " Public? <input type=checkbox id='summaryPublic' />" +
        "<div><textarea placeholder='Summary' id='summaryContent'></textarea></div>" +
        "<input type=button value='Create' onclick=submitSummary('summaryTitle','summaryTopic','summaryPublic','summaryContent') /></div>";
    html += formHtml;
    document.getElementById("main").innerHTML = html;
    updateSummaryList(summariesHandler("summaries"));
}
