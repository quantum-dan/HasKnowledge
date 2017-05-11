module Handler.Account where

import Import
import Yesod.Form.Jquery

data Username = Username Text

usernameForm :: Html -> MForm Handler (FormResult Username, Widget)
usernameForm = renderDivs $ Username
  <$> areq textField "Display name" Nothing

postUsernameR :: Handler Html
postUsernameR = do
  ((result, _), _) <- runFormPost usernameForm
  mauth <- maybeAuth
  case mauth of
    Just auth -> case result of
      FormSuccess (Username username) -> do
        updateUsername username auth
        redirect HomeR
      _ -> defaultLayout [whamlet|<p>Form error|]
    Nothing -> defaultLayout [whamlet|<p>Not logged in|]

updateUsername :: Text -> Entity User -> HandlerT App IO ()
updateUsername newUsername auth = runDB $
  update (entityKey auth) [UserName =. Just newUsername]

