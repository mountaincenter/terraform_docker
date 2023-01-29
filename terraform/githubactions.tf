data "tls_certificate" "github_actions" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  # ref: https://qiita.com/minamijoyo/items/eac99e4b1ca0926c4310
  # ref: https://zenn.dev/yukin01/articles/github-actions-oidc-provider-terraform
  thumbprint_list = [data.tls_certificate.github_actions.certificates[0].sha1_fingerprint]
}

# GitHub Actions側からはこのIAM Roleを指定する
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

# see: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services#configuring-the-role-and-trust-policy
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

    # OIDCを利用できる対象のGitHub Repositoryを制限する
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.full_paths
    }
  }
}

# 実際に利用する際にはこれに加えてdeny定義を追加付与するなどして、CI/CD用にカスタマイズすることを強く推奨
resource "aws_iam_role_policy_attachment" "admin" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.github_actions.name
}