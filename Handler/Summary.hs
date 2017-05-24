module Handler.Summary where

import Import
import Data.Aeson.Types (Result (..))

data FormSummary = FormSummary {
  fsTitle :: Text,
  fsTopic :: Text,
  fsContent :: Textarea,
  fsPublic :: Bool
                               }

createSummaryForm :: Html -> MForm Handler (FormResult FormSummary, Widget)
createSummaryForm = renderDivs $ FormSummary
  <$> areq textField "Title" Nothing
  <*> areq textField "Topic" Nothing
  <*> areq textareaField "Summary" Nothing
  <*> areq checkBoxField "Public?" Nothing

getSummariesR :: Handler TypedContent
getSummariesR = do
  (summaryForm, enctype) <- generateFormPost createSummaryForm
  mAuth <- maybeAuth
  summaries <- case mAuth of
    Just auth -> getSummaries $ entityKey auth
    Nothing -> getPublicSummaries
  selectRep $ do
    provideJson summaries
    provideRep $ defaultLayout $ do
      setTitle "Summaries"
      $(widgetFile "summarylist")

postSummariesR :: Handler TypedContent
postSummariesR = do
  mAuth <- maybeAuth
  case mAuth of
    Nothing -> redirect HomeR
    Just auth -> do
      mSummary <- parseJsonBody
      ((result, _), _) <- runFormPost createSummaryForm
      case mSummary of
        Success summary -> do
          _ <- addSummary auth summary
          redirect SummariesR
        Error _ ->
          case result of
            FormSuccess fs -> do
              _ <- addSummaryForm auth fs
              redirect SummariesR
            _ -> redirect SummariesR

getSummaryR :: Key Summary -> Handler TypedContent
getSummaryR sId = do
  mAuth <- maybeAuth
  mSummary <- getSummary sId mAuth
  case mSummary of
    Nothing -> redirect SummariesR
    Just summary -> selectRep $ do
      provideJson summary
      provideRep $ defaultLayout $ do
        setTitle $ toHtml $ summaryTitle summary
        $(widgetFile "summary")

getSummary :: Key Summary -> Maybe (Entity User) -> HandlerT App IO (Maybe Summary)
  -- Also verifies that the user has access to the summary in question
getSummary sId mAuth = do
  mSummary <- runDB $ get sId
  return $ mSummary >>= (\summary -> do
                            if (summaryPublicAccess summary) then Just summary
                              else mAuth >>= (\auth ->
                                                if (entityKey auth) == (summaryUserId summary) then Just summary else Nothing)
                        )

addSummaryForm :: Entity User -> FormSummary -> HandlerT App IO ()
addSummaryForm auth (FormSummary title topic content public) = do
  addSummary auth $ Summary title topic (entityKey auth) (unTextarea content) public

addSummary :: Entity User -> Summary -> Handler ()
addSummary auth summary = do
  let uId = entityKey auth
  _ <- runDB $ insert $ summary {summaryUserId = uId}
  return ()

getSummaries :: Key User -> HandlerT App IO [Entity Summary]
getSummaries uId = runDB $ selectList ([SummaryUserId ==. uId] ||. [SummaryPublicAccess ==. True]) []

getPublicSummaries :: HandlerT App IO [Entity Summary]
getPublicSummaries = runDB $ selectList [SummaryPublicAccess ==. True] []
