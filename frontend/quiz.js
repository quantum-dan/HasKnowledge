// Functions for working with quizzes

function updateQuizList(handler) { // Handler receives a list of quizzes
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "http://www.hasknowledge.net/quizzes", true);
    xhr.onreadystatechange = function() {
        var result = xhr.responseText;
        var quizzes = JSON.parse(result);
        handler(quizzes);
    };
    xhr.send();
}

function quizzesToList(quizzes, listId) {
    result = "";
    quizzes.forEach(function(quiz) {
        listItem = "<li><a href='/quiz/" + quiz.id.toString() + "'>" + quiz.title + "</a></li>";
        result += listItem;
    });
    document.getElementById(listId).innerHTML = result;
}

function createQuiz(titleId, topicId, publicId, listId) {
    data = {
        topic: document.getElementById(topicId).value,
        userId: 0,
        publicAccess: document.getElementById(publicId).checked,
        id: 0,
        title: document.getElementById(titleId).value
    };
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/mkquiz", true);
    xhr.onreadystatechange = updateQuizList(function(quizzes) {quizzesToList(quizzes, listId);});
    xhr.send(JSON.stringify(data));
}

function quizzesSetup() {
    html = "<div><input id='title' type='text' placeholder='title' /><input id='topic' type='text' placeholder='topic' /><input type='checkbox' id='public' /><input type='button' onclick=createQuiz('title','topic','public','quizzes') /></div><ul id='quizzes' style='text-align:left;'></ul>";
    document.getElementById("main").innerHTML = html;
    updateQuizList(function(quizzes) {quizzesToList(quizzes, "quizzes");});
}

var total = 0;
var correct = 0;

function quizSetup() {
    total = 0;
    correct = 0;
    html = ""
}
