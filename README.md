This is a demonstration of how to rig a [Quarto](https://quarto.org/) document that:

1. Uses the Drive API via the [googledrive R package](https://googledrive.tidyverse.org/),
   i.e. auth is required.
2. Will be deployed on a platform, such as [Posit Connect](https://posit.co/products/enterprise/connect/) or [Posit Connect Cloud](https://connect.posit.cloud/).

This demonstration shows how to use a Google service account for this task, which is generally better suited to a deployed data product than a user token.
However, it is possible to something similar with a user token and a [similar demonstration is available for the gmailr R package](https://github.com/r-lib/gmailr/blob/main/inst/deployed-token-demo/README.md).

## Interactive setup

The [`token-setup.R`](token-setup.R) script contains setup code that must be run interactively, in your primary computing environment.

This code should NOT be executed in the deployed data product.
There's no reason for this code to even be part of the deployment.

After the successful completion of `token-setup.R`, an encrypted service account token will be stored in the file `service_account_cred_enc.json`.

Pre-requisites:

* A Google Cloud Platform (GCP) project.
* A service account, within that GCP project.
* A service account "key"", associated with that account.
  This takes the form of a JSON file.
  
For detailed instructions, see: <https://gargle.r-lib.org/articles/get-api-credentials.html#service-account-token>.

In `token-setup.R`, you provide the path to this JSON file to `googledrive::drive_auth(path =)` and also execute `drive_user()`:

```r
drive_auth(path = "service_account_cred.json")
drive_user()
```

This is just to confirm that the credential works and is associated with the intended service account.

Next, using `gargle::secret_make_key()`, create a secret key to use when encrypting the service account token and then store that key as an environment variable. In `.Renviron`, you'll add a line like:

```
GOOGLEDRIVE_DEPLOY_DEMO_KEY=xxxyyyzzz
```

`usethis::edit_r_environ()` is a handy way to access that file.
Remember that changes to `.Renviron` don't take effect until you restart R.

Finally, use the secret key to create a second, encrypted JSON file containing the service account token:

```r
secret_encrypt_json(
  "service_account_cred.json",
  path = "service_account_cred_enc.json",
  key = "GOOGLEDRIVE_DEPLOY_DEMO_KEY"
)
```

`token-setup.R` is code that you run once.
Or, more realistically, you run it "every now and then".
There are various reasons why a credential might need to be replaced, in which case you need to go through these steps again.

At the end of `token-setup.R`, we do some more interactive tests to verify that the token has the expected type, for example.
We also double check that the encrypted JSON can't be read in the normal fashion.

In terms of version control and deployment:

* You **do not** want to commit, push, or deploy the unencrypted token file, `service_account_cred.json`.
* You **do** want to commit, push, and deploy the encrypted token file, `service_account_cred_enc.json`.

## Deployed product

[`googledrive-with-encrypted-token.qmd`](googledrive-with-encrypted-token.qmd) is a Quarto document.
The intent is to show how a deployed Quarto document could use an encrypted service account token to do Google Drive tasks.
In this simple example, we find a specific Drive file.
If it doesn't exist we create it.
Then we toggle its "starred" status from `TRUE` to `FALSE` or from `FALSE` to `TRUE`.

This chunk (attempts to) read the stored, encrypted token from file and tells googledrive to use it.

```r
library(googledrive)

try(drive_auth(
  path = gargle::secret_decrypt_json(
    "service_account_cred_enc.json",
    key = "GOOGLEDRIVE_DEPLOY_DEMO_KEY"
  )
))
```

For this to work, the encryption key must be available as a (secure) environment variable named `"GOOGLEDRIVE_DEPLOY_DEMO_KEY"` in the deployed environment.

From that point on, the googledrive usage is completely routine.

When deploying, it is important that all of these files are included:

* `googledrive-with-encrypted-token.qmd` or, in general, the code that creates
  the data produce (report, dashboard, app, whatever)
* `service_account_cred_enc.json` or, in general, the file that holds the
  stored, encrypted service account token

See the deployed product here: [Starring and unstarring a Drive file with an encrypted credential](https://connect.posit.cloud/jennybc/content/01919663-1203-882a-e659-1ac04d713329), hosted on Posit Connect Cloud.

## Less secure, but simpler, variation

If your project lives only in safe, internal spaces, you might not need to encrypt the service account token.
For example, if you don't use hosted version control or you do, but the repository (or perhaps the entire host) is private to your organization, it could be acceptable to commit and deploy the unencrypted JSON.

In that case, token setup boils down to verifying the JSON file works for auth and putting it in a convenient place.
The call to `gargle::secret_encrypt_json()` is eliminated.

The auth chunk of the `.qmd` also gets simpler, i.e. the `gargle::secret_decrypt_json()` call is eliminated:

```r
try(drive_auth(path = "service_account_cred.json"))
```

## Gotcha

Remember that the service account will need to have permission to access any relevant Drive resources.
A common mistake is to assume that because you own a Drive file and you have control of the service account, that implies that the service account can automatically act on your files.
That's not true!

You must explicitly grant the service account appropriate permissions on the necessary file(s), folder(s), or shared drive.
