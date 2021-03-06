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
        // listItem = "<li><a href='/quiz/" + quiz.id.toString() + "'>" + quiz.title + "</a></li>";
        listItem = "<li onclick='quizSetup(" + quiz.id.toString() + ")'>" + quiz.title + "</li>";
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
    xhr.open("POST", "/quizzes", true);
    xhr.onreadystatechange = updateQuizList(function(quizzes) {quizzesToList(quizzes, listId);});
    xhr.send(JSON.stringify(data));
}

function quizzesSetup() {
    html = "<div id='div_quiz_create'>Create Quiz: <input id='title' type='text' placeholder='title' /><input id='topic' type='text' placeholder='topic' />" +
        " Public? <input type='checkbox' id='public' /><input type='button' id='button_quiz_create' onclick=createQuiz('title','topic','public','quizzes') value='Create' />" +
        "</div><ul id='quizzes' style='text-align:left;'></ul>";
    document.getElementById("main").innerHTML = html;
    updateQuizList(function(quizzes) {quizzesToList(quizzes, "quizzes");});
}

var quizData = {
    quiz: null,
    correct: 0,
    total: 0
};

function answerToHtml(answer) {
    html = "<li onclick=handleAnswer(this," + answer.correct.toString() + ")>" + answer.content + "</li>";
    return html;
}

function questionToHtml(question) {
    html = "<div style='text-align:left'>" + question.question + "<ul>";
    question.answers.forEach(function(answer) { html += answerToHtml(answer); });
    html += "</ul></div>";
    return html;
}

function showScore() {
    percentage = (quizData.correct / quizData.total * 100).toString() + "%";
    result = "Correct: " + quizData.correct.toString() + "; Total: " + quizData.total.toString() + "; Accuracy: " + percentage;
    return result;
}

function makeAnswerId(contentId, correctId) {
    return {
        correctId: correctId,
        contentId: contentId
    };
}

function quizToHtml(quiz) {
    html = "<h3>" + quiz.maybequiz.title + " (" + quiz.maybequiz.topic + ")</h3><div style='text-align:left'>";
    quiz.questions.forEach(function(question){ html += questionToHtml(question); });
    html += "<div onclick='this.innerHTML=showScore()'>Show Score</div>";
    html += "</div>";
    html += "<div>" + "<input type=text placeholder='Question' id='questionAdd' />" +
        "<input type=text placeholder='Answer 1' id='questionAnswer1' />" + " Correct? <input type=checkbox id='questionCorrect1' />" +
        "<input type=text placeholder='Answer 2' id='questionAnswer2' />" + " Correct? <input type=checkbox id='questionCorrect2' />" +
        "<input type=button value='Add' onclick=createQuestion('questionAdd'," +
        "[makeAnswerId('questionAnswer1','questionCorrect1'),makeAnswerId('questionAnswer2','questionCorrect2')]," + quiz.id.toString() +
        ") />" +
        "</div>";
    html += "<div onclick='quizzesSetup()'>Return</div>";
    return html;
}

function handleAnswer(object, correct) {
    quizData.total++;
    if (correct) {
        quizData.correct++;
    }
    object.innerHTML += (" (" + correct.toString() + ")");
}

function quizSetup(quizId) {
    quizData.correct = 0;
    quizData.total = 0;
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "/quiz/" + quizId.toString(), true);
    xhr.onreadystatechange = function() {
        document.getElementById("main").innerHTML = xhr.responseText; // For debugging
        maybeQuiz = JSON.parse(xhr.responseText);
        if (maybeQuiz.maybequiz) {
            quizData.quiz = maybeQuiz;
            document.getElementById("main").innerHTML = quizToHtml(maybeQuiz);
        }
    };
    xhr.send();
}

function createAnswers(answerIds, questionId, quizId) {
    var answers = answerIds.map(answerId => {return {
        correct: document.getElementById(answerId.correctId).checked,
        content: document.getElementById(answerId.contentId).value,
        questionId: questionId
    }; });
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/answer", true);
    xhr.onreadystatechange = function() {
        quizSetup(quizId);
    };
    xhr.send(JSON.stringify(answers));
}

function createQuestion(questionId, answerIds, quizId) {
    var question = {
        question: document.getElementById(questionId).value,
        quizId: quizId
    };
    var xhr = new XMLHttpRequest();
    xhr.open("POST", "/question/" + quizId.toString(), true);
    xhr.onreadystatechange = function() {
        var response = xhr.responseText;
        var responseJson = JSON.parse(response);
        createAnswers(answerIds, responseJson, quizId);
    };
    xhr.send(JSON.stringify(question));
}
