data "google_project" "project" {
  project_id = "${var.project}"
}

resource "google_cloudbuild_trigger" "build" {
  project = "${data.google_project.project.project_id}"
  
  trigger_template {
    branch_name = "master"
    project = "${data.google_project.project.project_id}"
    repo_name   = "${var.repository}"
  }

  build {
    # Build the application and Docker container.
    step {
      name = "gcr.io/cloud-builders/docker"
      args = "build -t gcr.io/$PROJECT_ID/$REPO_NAME:$COMMIT_SHA -f Dockerfile ."
    }

    # Push the Docker container to Google Container Registry.
    step {
      name = "gcr.io/cloud-builders/docker"
      args = "push gcr.io/$PROJECT_ID/$REPO_NAME:$COMMIT_SHA"
    }

    # Deploy the application to the Nomad cluster:
    # Since Google Cloud Build can not contact internal instances,
    # this will create an instance in the same network as
    # the Nomad cluster. This allows us to safely deploy the
    # application without granting 0.0.0.0/0 access.
    step {
      name = "gcr.io/erik-playground/terraform-builder"
      args = "-var image=gcr.io/$PROJECT_ID/$REPO_NAME:$COMMIT_SHA"
    }
  }
}