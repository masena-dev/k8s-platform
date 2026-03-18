const fs = require("fs");

module.exports = async ({ github, context, core }) => {
  // Helper: map success boolean to status object
  function getStatus(success) {
    if (success) {
      return { icon: ":white_check_mark:", text: "Valid" };
    }
    return { icon: ":x:", text: "Failed" };
  }

  // Read components from shared summary file
  const summaryPath =
    process.env.TERRAFORM_VALIDATION_SUMMARY_FILE ||
    "terraform-validation-summary.txt";
  let components = [];

  if (fs.existsSync(summaryPath)) {
    const summaryContent = fs.readFileSync(summaryPath, "utf8").trim();
    if (summaryContent.length > 0) {
      components = summaryContent.split("\n").flatMap((line) => {
        try {
          const obj = JSON.parse(line);
          return [{ name: obj.label, success: obj.success }];
        } catch {
          return [];
        }
      });
    }
  }

  // Build comment body
  let comment = `## Terraform Validation - K8s Starter Kit\n\n`;

  if (components.length === 0) {
    comment += `**No validation results found** — check workflow logs.\n`;
  } else {
    const hasErrors = components.some((c) => !c.success);

    if (hasErrors) {
      comment += `**Validation failed** — fix errors before merging.\n\n`;
    } else {
      comment += `**All components valid** — safe to merge.\n\n`;
    }

    // Summary table
    comment += `### Summary\n\n| Component | Status |\n|-----------|--------|\n`;
    components.forEach((comp) => {
      const status = getStatus(comp.success);
      comment += `| ${comp.name} | ${status.icon} ${status.text} |\n`;
    });
    comment += `\n`;

    // Next steps
    comment += `### Next Steps\n\n`;
    if (hasErrors) {
      comment += `**Fix validation errors** — run \`terraform validate\` locally in the failing directories.\n`;
    } else {
      comment += `**Safe to merge** — all Terraform configurations and Helm charts are valid.\n`;
    }

    // Fail the workflow if any validation failed
    if (hasErrors) {
      core.setFailed("Terraform validation failed — check the summary above");
    }
  }

  comment += `\n---\n*Commit: ${context.sha.substring(0, 7)}*`;

  // Find existing bot comment or create new one
  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: context.issue.number,
  });

  const botComment = comments.find(
    (c) =>
      c.user.type === "Bot" &&
      c.body.includes("Terraform Validation - K8s Starter Kit"),
  );

  if (botComment) {
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: botComment.id,
      body: comment,
    });
  } else {
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: context.issue.number,
      body: comment,
    });
  }
};
