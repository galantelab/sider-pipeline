{
	"Statement": [
		{
			"Action": [
				"s3:ListAllMyBuckets"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::*"
		},
		{
			"Action": [
				"s3:ListBucket",
				"s3:GetBucketLocation"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::"
		},
		{
			"Action": [
				"s3:PutObject",
				"s3:GetObject",
				"s3:DeleteObject"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::/*"
		}
	],
	"Version": "2012-10-17"
}
