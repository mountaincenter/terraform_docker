data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json
  description        = "IAM Role for GitHub Actions OIDC"
}

locals {
  allowed_github_repositories = [
    "terraform_docker",
  ]
  github_org_name = "my-organization"
  full_paths = [
    for repo in local.allowed_github_repositories : "repo:${local.github_org_name}/${repo}:*"
  ]
}

data "aws_iam_policy_document" "github_actions" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
      ]
    }
    condition {
      test     = "Stringlike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.full_paths
    }
  }
}

# あとでdeny定義を追加付与
resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.github_actions.name
}