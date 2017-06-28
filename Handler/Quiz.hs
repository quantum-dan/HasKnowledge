module Handler.Quiz where

import Import
import Yesod.Form.Jquery
import Data.Aeson.Types (Result(..))
import Data.List (nub)

data FormQuiz = FormQuiz {
  fqTitle :: Text,
  fqTopic :: Text,
  fqPublic :: Bool
}

data FormQuestion = FormQuestion {
  {- Hardcoded answers is ugly, but I don't see a better way to do it with plain HTML -}
  fqQuestion :: Text,
  fqAnswer1 :: Text, fqAnswer1C :: Bool,
  fqAnswer2 :: Text, fqAnswer2C :: Bool,
  fqAnswer3 :: Text, fqAnswer3C :: Bool,
  fqAnswer4 :: Text, fqAnswer4C :: Bool
}

createQuestionForm :: Html -> MForm Handler (FormResult FormQuestion, Widget)
createQuestionForm = renderDivs $ FormQuestion
  <$> areq textField "Question" Nothing
  <*> areq textField "Answer 1" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 2" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 3" Nothing
  <*> areq checkBoxField "Correct?" Nothing
  <*> areq textField "Answer 4" Nothing
  <*> areq checkBoxField "Correct?" Nothing

createAnswers :: [(Text, Bool)] -> Key Question -> Handler ()
createAnswers ((answer, correct):answers) qId = do
  _ <- runDB $ insert (Answer qId answer correct)
  createAnswers answers qId
createAnswers [] _ = return ()

createQuestion :: Question -> [(Text, Bool)] -> Key Quiz -> Handler ()
createQuestion question answers qId = do
  questionId <- runDB $ insert $ question {questionQuizId = qId}
  _ <- createAnswers answers questionId
  return ()

createQuestionF :: FormResult FormQuestion -> Key Quiz -> HandlerT App IO ()
createQuestionF formResult qId =
  case formResult of
    FormSuccess (FormQuestion question a1 c1 a2 c2 a3 c3 a4 c4) -> createQuestion (Question qId question) [(a1, c1), (a2, c2), (a3, c3), (a4, c4)] qId
    _ -> return ()

createQuizForm :: Html -> MForm Handler (FormResult FormQuiz, Widget)
createQuizForm = renderDivs $ FormQuiz
  <$> areq textField "Title" Nothing
  <*> areq textField "Topic" Nothing
  <*> areq checkBoxField "Public" Nothing

createQuizF :: FormResult FormQuiz -> Key User -> HandlerT App IO ()
createQuizF formResult userId =
  case formResult of
    FormSuccess (FormQuiz title topic public) -> createQuiz (Quiz title userId topic public) userId
    _ -> return ()

createQuiz :: Quiz -> Key User -> Handler ()
createQuiz quiz userId = do
  _ <- runDB $ insert $ quiz {quizUserId = userId}
  return ()

getQuizzesR :: Handler TypedContent
getQuizzesR = do
  mAuth <- maybeAuth
  (quizForm, enctype) <- generateFormPost createQuizForm
  quizzes <- getAvailableQuizzes $ fmap entityKey mAuth
  selectRep $ do
    provideJson quizzes
    provideRep $ defaultLayout $ do
      setTitle "Quizzes"
      $(widgetFile "quizlist")

postQuizzesR :: Handler Html
postQuizzesR = do
  auth <- requireAuth
  ((result, _), _) <- runFormPost createQuizForm
  jsonQuiz <- parseJsonBody
  case jsonQuiz of
    Success quiz -> do
      createQuiz quiz $ entityKey auth
      redirect QuizzesR
    Error _ -> do
      createQuizF result (entityKey auth)
      redirect QuizzesR

data QuizQuestion = QuizQuestion Text [Answer]
instance ToJSON QuizQuestion where
  toJSON (QuizQuestion question answers) = object
    [
      "question" .= question
      , "answers" .= answers
    ]

data QuizInfo = QuizInfo (Maybe Quiz) [QuizQuestion] Bool

instance ToJSON QuizInfo where
  toJSON (QuizInfo q qs o) = object
    [
      "maybequiz" .= q
      , "questions" .= qs
      , "owner" .= o
    ]

getQuizR :: Key Quiz -> Handler TypedContent
getQuizR qId = do
  (questionForm, enctype) <- generateFormPost createQuestionForm
  questions <- getQuestions qId
  let jsonQuestions = map (\(question, answers) -> QuizQuestion (questionQuestion $ entityVal question) (map entityVal answers)) questions
  mAuth <- maybeAuth
  quiz <- runDB $ get qId
  -- Get the data out of the various Monads involved and determine if the user is the owner of the quiz
  let ownsQuiz = case (quiz >>= (\q -> mAuth >>= (\m -> return (entityKey m == quizUserId q)))) of
        Nothing -> False
        Just x -> x
  let quizAccess = ownsQuiz ||
        case quiz of
          Nothing -> False
          Just q -> quizPublicAccess q
  selectRep $ do
    provideJson $ case quizAccess of
      True -> QuizInfo quiz jsonQuestions ownsQuiz
      False -> QuizInfo Nothing [] False
    provideRep $ defaultLayout $ do
      setTitle "Quiz"
      $(widgetFile "quiz")

deleteQuizR :: Key Quiz -> Handler TypedContent
deleteQuizR quizId = do
  auth <- requireAuth
  mQuiz <- runDB $ get quizId
  case mQuiz of
    Nothing -> redirect QuizzesR
    Just quiz -> if quizUserId quiz == entityKey auth
      then (runDB $ delete quizId) >> redirect QuizzesR
      else selectRep $ do
        provideJson $ object ["error" .= ("You do not own this quiz" :: Text)]
        provideRep $ return [shamlet|<p>You do not own this quiz|]

postQuestionR :: Key Quiz -> Handler TypedContent
postQuestionR qId = do
  auth <- requireAuth
  mQuiz <- runDB $ get qId
  case mQuiz of
    Just quiz ->
      if (quizUserId quiz) == entityKey auth -- Verify that the person sending the request owns the quiz
        then do
          ((result, _), _) <- runFormPost createQuestionForm
          jsonQuestion <- parseJsonBody
          case jsonQuestion of
            Success (question, answers) -> do
              createQuestion question answers qId
              redirect (QuizR qId)
            Error _ -> do
              createQuestionF result qId
              redirect (QuizR qId)
        else redirect (QuizR qId)
    Nothing -> redirect HomeR

getFilteredQuizzesR :: Text -> Handler TypedContent
getFilteredQuizzesR topic = do
  mAuth <- maybeAuth
  quizzes <- case mAuth of
    Just auth -> filterByTopic (entityKey auth) topic
    Nothing -> filterByTopicNoUser topic
  selectRep $ do
    provideJson quizzes
    provideRep $ do
      (quizForm, enctype) <- generateFormPost createQuizForm
      defaultLayout $ do
        setTitle $ toHtml $ "Quizzes with Topic: " ++ topic
        $(widgetFile "quizlist")

getAvailableQuizzes :: Maybe (Key User) -> Handler [Entity Quiz]
getAvailableQuizzes mUserId = case mUserId of
  Nothing -> getPublicQuizzes
  Just userId -> do
    ownedOrShared <- runDB $ do
      shared <- selectList [SharedQuizUserId ==. userId] []
      let ownedFilter = [QuizUserId ==. userId]
      let sharedQuizIds = map (sharedQuizQuizId . entityVal) shared
      let ownedOrSharedFilter = foldr (||.) ownedFilter $ map (\id -> [QuizId ==. id]) sharedQuizIds
      selectList ownedOrSharedFilter []
    public <- getPublicQuizzes
    return $ ownedOrShared ++ public

getPublicQuizzes :: Handler [Entity Quiz]
getPublicQuizzes = runDB $ selectList [QuizPublicAccess ==. True] []

getAnswers :: Key Question -> HandlerT App IO [Entity Answer]
getAnswers qId = runDB $ do
  answers <- selectList [AnswerQuestionId ==. qId] []
  return answers

getAllAnswers :: [Entity Question] -> HandlerT App IO [(Entity Question, [Entity Answer])]
-- Loop to recursively get answers, paird with the appropriate questions, for a given quiz
getAllAnswers (q:questions) = do
  answers <- getAnswers $ entityKey q
  rest <- getAllAnswers questions
  return $ (q, answers):rest
getAllAnswers [] = return []

getQuestions :: Key Quiz -> HandlerT App IO [(Entity Question, [Entity Answer])]
getQuestions qId = do
  questions <- runDB $ selectList [QuestionQuizId ==. qId] []
  allAnswers <- getAllAnswers questions
  return allAnswers

filterByTopic :: Key User -> Text -> Handler [Entity Quiz]
filterByTopic userId topic = runDB $ selectList (([QuizPublicAccess ==. True] ||. [QuizUserId ==. userId]) ++ [QuizTopic ==. topic]) []

filterByTopicNoUser :: Text -> Handler [Entity Quiz]
filterByTopicNoUser topic = runDB $ selectList [QuizPublicAccess ==. True, QuizTopic ==. topic] []
