this is a example of how one would 
build and deploy a rest api via terraform and aws

there are not a whole lot of good resources for this so the idea here is simple....
- create your lambda function
- you write the endpoint in your swagger doc (api.yaml)
- update a local array of lambdas for templating, just add the function
- add the templating to your rest function
- profit 😎

