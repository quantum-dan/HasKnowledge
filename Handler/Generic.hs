module Handler.Generic where
{- Generic Handler functions which can be adapted to various handlers.
If there is a common pattern in handler functions, make it into a function
with appropriate parameters and put it here. -}

import Import

addNewOwnedContent :: Key User -> (Html -> MForm Handler (FormResult a, Widget)) -> (FormResult a -> Key User -> Handler b) -> Handler b
addNewOwnedContent userId form formHandler = do
  ((result, _), _) <- runFormPost form
  formHandler result userId

data Ownership a = Ownership { content :: a, owned :: Bool, access :: Bool } | NoContent
getOwnedContent :: Maybe (Entity User) -> Maybe (Entity a) -> (Key User -> a -> Bool) -> (Maybe (Key User) -> Entity a -> Bool) -> Ownership (Entity a)
getOwnedContent mUser mValue ownership access = case mValue of
  Nothing -> NoContent
  Just value -> case mUser of
    Nothing -> Ownership value False (access Nothing value)
    Just user -> Ownership value (ownership (entityKey user) $ entityVal value) (access (Just $ entityKey user) value)
