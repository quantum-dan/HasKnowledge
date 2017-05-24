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

getTopicsR :: Key NotesUser -> Handler TypedContent
getTopicsR userId = do
  topics <- runDB $ selectList [NotesTopicUserId ==. userId] []
  selectRep $ do
    provideJson topics
    provideRep $ do
      (topicForm, enctype) <- generateFormPost createNotesTopicForm
      defaultLayout $(widgetFile "topics")

getNotesR :: Key NotesTopic -> Handler TypedContent
getNotesR topicId = do
  notes <- runDB $ selectList [NoteTopicId ==. topicId] []
  selectRep $ do
    provideJson notes
    provideRep $ do
      (noteForm, enctype) <- generateFormPost createNoteForm
      defaultLayout $(widgetFile "notes")

postTopicsR :: Key NotesUser -> Handler TypedContent
postTopicsR userId = do
  topicJson <- (parseJsonBody :: Handler (Result NotesTopic))
  ((result, _), _) <- runFormPost createNotesTopicForm
  _ <- case topicJson of
    Success topic -> do
      _ <- runDB $ insert topic{notesTopicUserId = userId}
      return ()
    Error _ -> case result of
      FormSuccess (NotesTopicF topic) -> do
        _ <- runDB $ insert $ NotesTopic topic userId
        return ()
      _ -> return ()
  selectRep $ do
    provideJson $ object []
    provideRep $ return [shamlet|<p>Success!|]

postNotesR :: Key NotesTopic -> Handler TypedContent
postNotesR topicId = do
  noteJson <- (parseJsonBody :: Handler (Result Note))
  ((result, _), _) <- runFormPost createNoteForm
  case noteJson of
    Success note -> do
      _ <- runDB $ insert note{noteTopicId = topicId}
      return ()
    Error _ -> case result of
      FormSuccess (NoteF content) -> do
        _ <- runDB $ insert $ Note topicId (unTextarea content)
        return ()
      _ -> return ()
  selectRep $ do
    provideJson $ object []
    provideRep $ return [shamlet|<p>Success!|]
