{
	"containerDefinitions": [
		{
			"name": "ECSPOVRayWorker",
			"image": "<DOCKERHUB_USER>/<DOCKERHUB_REPOSITORY>:<TAG>",
			"cpu": 512,
			"environment": [
				{
					"name": "AWS_REGION",
					"value": "<YOUR-CHOSEN-AWS-REGION>"
				},
				{
					"name": "SQS_QUEUE_URL",
					"value": "https://<YOUR_REGION>.queue.amazonaws.com/<YOUR_AWS_ACCOUNT_ID>/ECSPOVRayWorkerQueue"
				}
			],
			"memory": 512,
			"essential": true
		}
	],
	"family": "ECSPOVRayWorkerTask"
}
