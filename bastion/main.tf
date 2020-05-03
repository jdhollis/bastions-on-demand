data "aws_caller_identity" "env" {}

resource "aws_ecr_repository" "bastion" {
  name = "bastion"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.env.account_id}:root"]
      type        = "AWS"
    }
  }
}

data "aws_iam_policy_document" "public_key_fetcher" {
  statement {
    actions = [
      "iam:GetSSHPublicKey",
      "iam:ListSSHPublicKeys",
    ]

    resources = ["arn:aws:iam::${data.aws_caller_identity.env.account_id}:user/*"]
  }
}

resource "aws_iam_role" "public_key_fetcher" {
  name               = "public-key-fetcher"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "public_key_fetcher" {
  name   = "public-key-fetcher"
  policy = data.aws_iam_policy_document.public_key_fetcher.json
  role   = aws_iam_role.public_key_fetcher.id
}
