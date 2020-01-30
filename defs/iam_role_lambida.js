{
	"Statement": [
		{
			"Action": [
				"logs:*",
				"lambda:invokeFunction",
				"sqs:SendMessage",
				"ecs:RunTask"
			],
			"Effect": "Allow",
			"Resource": [
				"arn:aws:logs:*:*:*",
				"arn:aws:lambda:*:*:*:*",
				"arn:aws:sqs:*:*:*",
				"arn:aws:ecs:*:*:*"
			]
		}
	],
	"Version": "2012-10-17"
}
