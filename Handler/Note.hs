module Handler.Note where

import Import
import Data.Aeson.Types (Result(..))

data NotesUserF = NotesUserF { nufUsername :: Text }
createNotesUserForm :: Html -> MForm Handler (FormResult NotesUserF, Widget)
createNotesUserForm = renderDivs $ NotesUserF
  <$> areq textField "Username" Nothing

data NotesTopicF = NotesTopicF { ntfTitle :: Text }
createNotesTopicForm :: Html -> MForm Handler (FormResult NotesTopicF, Widget)
createNotesTopicForm = renderDivs $ NotesTopicF
  <$> areq textField "Topic" Nothing

data NoteF = NoteF { nfContent :: Textarea }
createNoteForm :: Html -> MForm Handler (FormResult NoteF, Widget)
createNoteForm = renderDivs $ NoteF
  <$> areq textareaField "Content" Nothing

postNotesUserR :: Handler TypedContent
postNotesUserR = do
  userJson <- (parseJsonBody :: Handler (Result NotesUser))
  ((result, _), _) <- runFormPost createNotesUserForm
  case userJson of
    Success user -> do
      _ <- runDB $ insert user
      return ()
    Error _ -> case result of
      FormSuccess (NotesUserF username) -> do
        _ <- runDB $ insert $ NotesUser username
        return ()
      _ -> return ()
  selectRep $ do
    provideJson $ object []
    provideRep $ return [shamlet|<p>Success!|]

getTopicsR :: Handler Html
getTopicsR = do
  auth <- requireAuth
  mNotesUser <- runDB $ getBy $ UniqueNotesUser $ userIdent $ entityVal auth
  case mNotesUser of
    Just notesUser -> do
      topics <- runDB $ selectList [NotesTopicUserId ==. entityKey notesUser] []
      (topicForm, enctype) <- generateFormPost createNotesTopicForm
      defaultLayout $(widgetFile "topics")
    Nothing -> redirect HomeR

getTopicsJsonR :: Key NotesUser -> Handler TypedContent
getTopicsJsonR userId = do
  topics <- runDB $ selectList [NotesTopicUserId ==. userId] []
  selectRep $ do
    provideJson topics
    provideRep $ do
      (topicForm, enctype) <- generateFormPost createNotesTopicForm
      defaultLayout $(widgetFile "topics")

getNotesR :: Key NotesTopic -> Handler TypedContent
getNotesR topicId = do
  notes <- runDB $ selectList [NoteTopicId ==. topicId] []
  mTopic <- runDB $ get topicId
  selectRep $ do
    provideJson notes
    provideRep $ do
      (noteForm, enctype) <- generateFormPost createNoteForm
      defaultLayout $(widgetFile "notes")

postTopicsR :: Handler Html
postTopicsR = do
  auth <- requireAuth
  mNotesUser <- runDB $ getBy $ UniqueNotesUser $ userIdent $ entityVal auth
  case mNotesUser of
    Just notesUser -> do
      ((result, _), _) <- runFormPost createNotesTopicForm
      case result of
        FormSuccess (NotesTopicF topic) -> do
          _ <- runDB $ insert $ NotesTopic topic $ entityKey notesUser
          redirect TopicsR
        FormFailure err -> defaultLayout [whamlet|Error: #{show err}|]
        _ -> defaultLayout [whamlet|Error|]
    Nothing -> redirect HomeR


postTopicsJsonR :: Key NotesUser -> Handler Value
postTopicsJsonR userId = do
  topicJson <- (parseJsonBody :: Handler (Result NotesTopic))
  case topicJson of
    Success topic -> do
      _ <- runDB $ insert topic{notesTopicUserId = userId}
      return $ object ["success" .= True]
    Error error -> return $ object ["error" .= error]

postNotesR :: Key NotesTopic -> Handler Html
postNotesR topicId = do
  ((result, _), _) <- runFormPost createNoteForm
  case result of
    FormSuccess (NoteF content) -> do
      _ <- runDB $ insert $ Note topicId $ unTextarea content
      redirect $ NotesR topicId
    _ -> defaultLayout [whamlet|Error in form submission!|]

postNotesJsonR :: Key NotesTopic -> Handler Value
postNotesJsonR topicId = do
  noteJson <- (parseJsonBody :: Handler (Result Note))
  case noteJson of
    Success note -> do
      _ <- runDB $ insert note{noteTopicId = topicId}
      return $ object ["success" .= True]
    Error error -> return $ object ["error" .= error]

getNotesJsonR :: Key NotesTopic -> Handler Value
getNotesJsonR topicId = do
  notes <- runDB $ selectList [NoteTopicId ==. topicId] []
  returnJson notes
