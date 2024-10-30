#!/usr/bin/env python

import argparse
import dataclasses
import os
import requests  # TODO: replace with http.client or urllib
import shutil
import subprocess
import typing as t


AwsCredential = t.Literal[
    "aws_access_key_id", "aws_secret_access_key", "aws_session_token"
]


class CLIException(Exception):
    pass


class TFEClientError(Exception):
    pass


class TFEClientResponseError(Exception):
    def __init__(self, response: requests.Response, message: str):
        super().__init__(
            f"TFE Client Error: {message}\nResponse code: {response.status_code}\nError: "
            f"{response.text}"
        )


class TFEVariableValidationError(Exception):
    def __init__(self, variable, message: str):
        super().__init__(f"TFEVariable {variable.id}: {message}")


@dataclasses.dataclass(eq=False)
class TFEVariable:
    """
    Subset of properties belonging to workspace variables in TFE.

    Default values taken from POST /vars docs:
    https://developer.hashicorp.com/terraform/cloud-docs/api-docs/workspace-variables#create-a-variable

    Would ideally use marshmallow, but don't want to rely on anything outside of stdlib.
    """

    key: str
    value: str
    category: t.Literal["terraform", "env"]
    id: t.Optional[str] = None
    type: t.Literal["vars"] = "vars"
    description: str = ""
    sensitive: bool = False
    hcl: bool = False

    def __post_init__(self):
        if self.type != "vars":
            raise TFEVariableValidationError(self, "type must be 'vars'")

        if self.category not in ["terraform", "env"]:
            raise TFEVariableValidationError(
                self,
                f"category must be one of 'terraform' or 'env'. Found '{self.category}'",
            )

    def __eq__(self, other):
        return self.id == other.id

    def exists(self):
        return self.id is not None and self.id != ""

    @classmethod
    def from_dict(cls, data: dict):
        return TFEVariable(
            id=data["id"],
            key=data["attributes"]["key"],
            category=data["attributes"]["category"],
            value=data["attributes"]["value"],
            description=data["attributes"]["description"],
            sensitive=data["attributes"]["sensitive"],
            hcl=data["attributes"]["hcl"],
        )


class TFEClient:
    """
    A client implementing a limited subset of the Terraform Cloud/Enterprise
    workspace API.
    """

    _variables_raw: t.Dict[t.Any, t.Any] = None
    _variables: t.List[TFEVariable] = []

    def __init__(self, organization, workspace_name, api_token):
        # TODO: remove testing safety and replace with other checks
        self.organization = organization
        self.workspace_name = workspace_name
        self.api_token = api_token

        self._session = requests.Session()
        self._session.headers.update(
            {
                "Authorization": f"Bearer {self.api_token}",
                "Content-Type": "application/vnd.api+json",
            }
        )

        self._get_workspace()

    def __del__(self):
        self._session.close()

    def _get_workspace(self):
        response = self._session.get(
            url=f"https://terraform.nimbis.io/api/v2/organizations/{self.organization}/workspaces",
            params={"search[name]": self.workspace_name},
        )

        if not response.ok:
            raise TFEClientResponseError(
                response, f"Unable to list workspaces in '{self.organization}'"
            )

        self.workspace_id = response.json()["data"][0]["id"]

    @property
    def variables(self) -> t.List[TFEVariable]:
        # There may be no variables in a workspace so we can't rely on the
        # length of _variables. Instead we check if _variables_raw has been
        # set.
        if not self._variables_raw:
            # We load all the variables the first time this is accessed. An
            # update operation requires an id and the only way to get the id
            # for a variable is to use the List endpoint and find it in the
            # response. This is cached, but can be updated by calling
            # TFEWorkspaceClient.refresh_variables().
            self._load_variables()

        return self._variables

    def refresh_variables(self):
        """
        Clear the current workspace variables cache and fetch the latest
        variables.
        """
        self._variables = []
        self._variables_raw = None
        self._load_variables()

    def _load_variables(self):
        """
        Get all variables in the TFEClient's workspace.
        """
        # https://developer.hashicorp.com/terraform/cloud-docs/api-docs/workspace-variables#list-variables
        response = self._session.get(
            f"https://terraform.nimbis.io/api/v2/workspaces/{self.workspace_id}/vars"
        )
        if not response.ok:
            msg = (
                f"Unable to get list of variables in workspace '{self.workspace_name}' in "
                f"'{self.organization}'"
            )
            raise TFEClientResponseError(response, msg)

        self._variables_raw = response.json()

        for variable in self._variables_raw["data"]:
            self._variables.append(TFEVariable.from_dict(variable))

    def create_variable(
        self,
        key: str,
        value: str,
        category: t.Literal["terraform", "env"],
        description: str = "",
        hcl: bool = False,
        sensitive: bool = False,
    ) -> TFEVariable:
        """
        Create a variable in the workspace.

        https://developer.hashicorp.com/terraform/cloud-docs/api-docs/workspace-variables#create-a-variable
        """
        payload = {
            "data": {
                "type": "vars",
                "attributes": {
                    "key": key,
                    "value": value,
                    "description": description,
                    "category": category,
                    "hcl": hcl,
                    "sensitive": sensitive,
                },
            }
        }

        response = self._session.post(
            url=f"https://terraform.nimbis.io/api/v2/workspaces/{self.workspace_id}/vars",
            json=payload,
        )

        if not response.ok:
            msg = (
                f"Unable to get create workspace variable '{key}' in "
                f"{self.organization}/{self.workspace_name}"
            )
            raise TFEClientResponseError(response, msg)

        return TFEVariable.from_dict(response.json()["data"])

    def update_variable(self, id: str, attributes: t.Dict[str, str]) -> TFEVariable:
        """
        Update a variable in the workspace.

        https://developer.hashicorp.com/terraform/cloud-docs/api-docs/workspace-variables#update-a-variable
        """
        valid_attributes = [
            "key",
            "value",
            "description",
            "category",
            "hcl",
            "sensitive",
        ]
        for attribute in attributes:
            if attribute not in valid_attributes:
                raise TFEClientError(
                    f"Invalid attribute: {attribute}. Valid attributes are "
                    f"{', '.join(valid_attributes)}"
                )

        payload = {"data": {"id": id, "type": "vars", "attributes": attributes}}

        response = self._session.patch(
            url=f"https://terraform.nimbis.io/api/v2/workspaces/{self.workspace_id}/vars/{id}",
            json=payload,
        )

        if not response.ok:
            msg = (
                f"Unable to update workspace variable '{id}' in "
                f"'{self.organization}/{self.workspace_name}'"
            )
            raise TFEClientResponseError(response, msg)

        return TFEVariable.from_dict(response.json()["data"])


def get_aws_config(profile: str, config_name: str) -> str:
    try:
        output = subprocess.run(
            f"aws --profile {profile} configure get {config_name}".split(),
            capture_output=True,
            check=True,
        )

    except subprocess.CalledProcessError as e:
        raise CLIException(f"AWS CLI error: {e.stderr.decode('utf-8')}") from e

    value = output.stdout.decode("utf-8").strip()
    return value


def update_tfe_credentials(
    tf_api_token: str,
    organization: str,
    workspace_name: str,
    aws_profile: str,
    prompt_for_confirmation: bool = True,
):
    # Retrieve AWS credentials from local config
    try:
        aws_access_key_id = get_aws_config(aws_profile, "aws_access_key_id")
        aws_secret_access_key = get_aws_config(aws_profile, "aws_secret_access_key")
        aws_session_token = get_aws_config(aws_profile, "aws_session_token")

    except CLIException as e:
        print(e)
        return

    # TODO: Force credentials refresh?

    aws_credential_defaults: t.List[TFEVariable] = [
        TFEVariable(
            key="AWS_ACCESS_KEY_ID",
            value=aws_access_key_id,
            category="env",
            description="AWS provider credentials.",
        ),
        TFEVariable(
            key="AWS_SECRET_ACCESS_KEY",
            value=aws_secret_access_key,
            category="env",
            description="AWS provider credentials.",
            sensitive=True,
        ),
        TFEVariable(
            key="AWS_SESSION_TOKEN",
            value=aws_session_token,
            category="env",
            description="AWS provider credentials.",
            sensitive=True,
        ),
    ]

    # Hardcode nimbis-dev to prevent accidental use on production sites.
    tfe = TFEClient(
        organization=organization, workspace_name=workspace_name, api_token=tf_api_token
    )

    # Determine which variables already exist. Existing variables will need to
    # be updated instead of created. If a variable has an id, we know it exists
    # and needs to be updated.
    for aws_var in aws_credential_defaults:
        for tf_var in tfe.variables:
            if aws_var.key == tf_var.key:
                # Variable exists, so set id so we know to update the variable
                # instead of creating it.
                aws_var.id = tf_var.id
                break

    user_confirmed = True

    # Tell user what will happen and ask for confirmation.
    if prompt_for_confirmation:
        msg = (
            f"The following operations will be applied to the '{tfe.workspace_name}' workspace "
            f"in the '{tfe.organization}' organization:\n"
        )
        for aws_var in aws_credential_defaults:
            if aws_var.id:
                msg += f"Update {aws_var.key}\n"

            else:
                msg += f"Create {aws_var.key}\n"

        msg += "\nConfirm? [Y/n]: "

        response = input(msg)

        if response.lower() not in ["y", "yes"]:
            user_confirmed = False
            print("\nCanceling operations.")

    if user_confirmed:
        print("")  # Add newline for formatting purposes

        for aws_var in aws_credential_defaults:
            if aws_var.id:
                tfe.update_variable(aws_var.id, attributes={"value": aws_var.value})
                print(f"Updated {aws_var.key}.")

            else:
                print(f"Created {aws_var.key}.")
                tfe.create_variable(
                    key=aws_var.key,
                    value=aws_var.value,
                    category=aws_var.category,
                    description=aws_var.description,
                    sensitive=aws_var.sensitive,
                )


def cli():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--organization",
        "-o",
        required=True,
        help="The TFE organization the workspace belongs to.",
    )
    parser.add_argument(
        "--workspace-name", "-w", required=True, help="The TFE workspace to update."
    )
    parser.add_argument(
        "--aws-profile",
        "-p",
        default=os.getenv("AWS_PROFILE"),
        help="The AWS profile in which to look for credentials.",
    )
    parser.add_argument(
        "--tf-api-token",
        "-t",
        default=os.getenv("TF_API_TOKEN"),
        help="TFE personal access token for authenticating with the TFE API.",
    )
    parser.add_argument(
        "--yes",
        "-y",
        action="store_true",
        help="If present, credentials will be updated without asking for confirmation",
    )

    args = parser.parse_args()
    if not args.tf_api_token:
        print("--tf-api-token or TF_API_TOKEN env must be set.")
        return

    if not args.aws_profile:
        print("--aws-profile or AWS_PROFILE env must be set.")
        return

    update_tfe_credentials(
        tf_api_token=args.tf_api_token,
        organization=args.organization,
        workspace_name=args.workspace_name,
        aws_profile=args.aws_profile,
        prompt_for_confirmation=not args.yes,
    )


if __name__ == "__main__":
    try:
        cli()

    except (CLIException, TFEClientResponseError) as e:
        print(e)
