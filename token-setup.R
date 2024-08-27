# This is setup that you run interactively once (or occasionally), to get the
# token ready.
# This code should not run in the deployed setting.
# This code does not need to be deployed at all.

library(googledrive)
library(gargle)      # necessary if you're going to encrypt the token
library(fs)          # my preferred package for file system work

# 1. Identify (perhaps create?) a Google service account.
# 2. Obtain a "service account key" (i.e. use an existing one or create a new
#    one). This will be a JSON file.
# 3. Put this file (or at least a copy of it) here in this folder.
#
# More documentation about the above:
# https://gargle.r-lib.org/articles/get-api-credentials.html#service-account-token
target_cred <- "~/path/to/the/place/I/keep/credentials/blah-blah-blah.json"
file_exists(target_cred)
cred_path <- "service_account_cred.json"
file_copy(target_cred, cred_path, overwrite = TRUE)

# Auth with this "service account key" as the credential.
drive_auth(path = cred_path)

# Verify that googledrive is acting on behalf of the desired service account.
drive_user()

# Let's assume you want to deploy an encrypted token.
# Make a secret key to use for symmetric encryption.
my_secret_key <- secret_make_key()
# [1] "uQZuWiSx21M2M96OPxQ-1w"

# Store this key as an environment variable:
# * Locally, for development
# * In the deployment context, e.g. on Connect
#
# Open your local, user-level .Renviron file:
usethis::edit_r_environ()
# Add this line to it (substitute your preferred name for the encryption key):
paste0("GOOGLEDRIVE_DEPLOY_DEMO_KEY=", my_secret_key)
# Save. Make sure the file ends with a newline.
# RESTART R.

# Verify that the secret is available in the env var.
Sys.getenv("GOOGLEDRIVE_DEPLOY_DEMO_KEY")

# Encrypt the credential and write it to a second local file.
(cred_path_enc <- cred_path |>
  path_ext_remove() |>
  paste0("_enc") |>
  path_ext_set("json"))

secret_encrypt_json(
  cred_path,
  path = cred_path_enc,
  key = "GOOGLEDRIVE_DEPLOY_DEMO_KEY"
)

# Admire the unencrypted and encrypted JSON files.
dir_ls(glob = "*.json")

# We can read the unencrypted cred by normal means.
(x <- jsonlite::fromJSON(cred_path))

# This should be "service_account".
x$type

# This should be the email of the desired service account.
x$ client_email

# We CANNOT read the encrypted cred by normal means.
# THIS SHOULD ERROR!
jsonlite::fromJSON(cred_path_enc)
# Error in parse_con(txt, bigint_as_char) :
#   lexical error: invalid char in json text.
#                                        TIvgOfZF0CiNciluAmNlJ7l7mvmyn6h
#                      (right here) ------^

# THE TOKEN SETUP IS DONE!
