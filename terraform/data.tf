data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "db_password_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db_secret.arn]
  }
}

data "aws_secretsmanager_secret" "secret" {
  depends_on = [
    aws_secretsmanager_secret_version.secret_password
  ]
  name = "${local.env}-${local.project}-db-password-secret"
}

data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}