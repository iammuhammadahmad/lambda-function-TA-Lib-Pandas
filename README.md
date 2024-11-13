# Lambda Function with Docker Image
This guide provides step-by-step instructions to build, test, and deploy a Lambda-compatible Docker image using Amazon ECR. It also includes setup for using TA-Lib (a technical analysis library) and pandas (a data analysis library) in the Lambda function. By following these steps, you’ll create a fully operational Lambda function that leverages Docker images for complex data processing.



## How to test the Lambda function locally

### Build Image:
To build the Docker image, use the `docker build` command. The following example names the image `docker-image` and gives it the `test` tag.

```bash
docker build --platform linux/amd64 -t docker-image:test .
```

> **Note**  
> The command specifies the `--platform linux/amd64` option to ensure compatibility with the Lambda execution environment, regardless of the architecture of your build machine.  
> 
> If you intend to create a Lambda function using the ARM64 instruction set architecture, change the command to use the `--platform linux/arm64` option instead.


### Testing the Image Locally

To test the image locally, start the Docker image with the `docker run` command. In this example, `docker-image` is the image name and `test` is the tag.

```bash
docker run --platform linux/amd64 -p 9000:8080 docker-image:test
```

This command runs the image as a container and creates a local endpoint at `localhost:9000/2015-03-31/functions/function/invocations`.

> **Note**  
> If you built the Docker image for the ARM64 instruction set architecture, be sure to use the `--platform linux/arm64` option instead of `--platform linux/amd64`.

### Invoking the Function Locally

From a new terminal window, post an event to the local endpoint.

#### Linux/macOS

Run the following `curl` command:

```bash
curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
```

This command invokes the function with an empty event and returns a response. If you're using your own function code rather than the sample function code, you might want to invoke the function with a JSON payload, as shown below:

```bash
curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"payload":"hello world!"}'
```
This will send a sample payload to your function.

## Deploying the Image to Amazon ECR and Creating the Lambda Function

### Step 1: Authenticate Docker CLI with Amazon ECR

Run the [get-login-password](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ecr/get-login-password.html) command to authenticate Docker with your Amazon ECR registry. Replace `111122223333` with your AWS account ID, and set the `--region` value to the AWS Region where you want to create the Amazon ECR repository.

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 111122223333.dkr.ecr.us-east-1.amazonaws.com
```

### Step 2: Create a Repository in Amazon ECR

Create an Amazon ECR repository with the `create-repository` command:

```bash
aws ecr create-repository --repository-name hello-world --region us-east-1 --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
```

> **Note**  
> The Amazon ECR repository must be in the same AWS Region as the Lambda function.

If successful, you will see a response similar to this:

```json
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:111122223333:repository/hello-world",
        "registryId": "111122223333",
        "repositoryName": "hello-world",
        "repositoryUri": "111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world",
        "createdAt": "2023-03-09T10:39:01+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": true
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```

Copy the `repositoryUri` from the output for use in the next steps.

### Step 3: Tag the Docker Image

Tag your local image to prepare it for upload to Amazon ECR. Replace `<ECRrepositoryUri>` with the `repositoryUri` that you copied from the previous step, making sure to add `:latest` at the end:

```bash
docker tag docker-image:test <ECRrepositoryUri>:latest
```

**Example:**

```bash
docker tag docker-image:test 111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
```

### Step 4: Push the Image to Amazon ECR

Deploy your local image to Amazon ECR using the `docker push` command. Include `:latest` at the end of the repository URI.

```bash
docker push 111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
```

### Step 5: Create an Execution Role for the Lambda Function

If you don't already have one, create an execution role for the Lambda function. You will need the Amazon Resource Name (ARN) of this role in the next step.

### Step 6: Create the Lambda Function

To create the Lambda function, use the `create-function` command. For `ImageUri`, specify the repository URI from earlier, including `:latest` at the end.

```bash
aws lambda create-function \
  --function-name hello-world \
  --package-type Image \
  --code ImageUri=111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest \
  --role arn:aws:iam::111122223333:role/lambda-ex
```

> **Note**  
> You can create a function using an image in a different AWS account, as long as the image is in the same Region as the Lambda function. For more information, see [Amazon ECR cross-account permissions](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policy-examples.html).

### Step 7: Invoke the Lambda Function

Invoke the function with the following command:

```bash
aws lambda invoke --function-name hello-world response.json
```

You should see a response similar to:

```json
{
  "ExecutedVersion": "$LATEST", 
  "StatusCode": 200
}
```

To view the function's output, check the `response.json` file.

### Updating the Function Code

To update the function code, rebuild the image, upload the new image to the Amazon ECR repository, and then use the `update-function-code` command to deploy the updated image to the Lambda function.

> **Note**  
> Lambda resolves the image tag to a specific image digest. If you point the image tag to a new image in Amazon ECR, Lambda doesn’t automatically update the function to use the new image. To deploy the new image to the same Lambda function, you must use the `update-function-code` command, even if the image tag in Amazon ECR remains the same.

```bash
aws lambda update-function-code \
  --function-name hello-world \
  --image-uri 111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest \
  --publish
```


[Document Refs Link](https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-instructions)
