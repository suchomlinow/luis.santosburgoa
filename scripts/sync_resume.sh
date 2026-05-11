#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SITE_DIR="${REPO_ROOT}/luis.santosburgoa-site"

RESUME_REPO_URL="${RESUME_REPO_URL:-git@github.com:suchomlinow/resume-lesb.git}"
RESUME_REPO_DIR="${RESUME_REPO_DIR:-}"
RESUME_SOURCE_TEX="${RESUME_SOURCE_TEX:-resume_eng.tex}"
SITE_CV_FILENAME="${SITE_CV_FILENAME:-LuisEmilioSantosBurgoa_CV_Eng.pdf}"
RESUME_REPO_TOKEN="${RESUME_REPO_TOKEN:-}"

TMP_DIR=""

cleanup() {
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}

trap cleanup EXIT

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "Site directory not found: ${SITE_DIR}" >&2
  exit 1
fi

if [[ -n "${RESUME_REPO_DIR}" ]]; then
  REPO_DIR="${RESUME_REPO_DIR}"
else
  TMP_DIR="$(mktemp -d)"
  REPO_DIR="${TMP_DIR}/resume-repo"
  CLONE_URL="${RESUME_REPO_URL}"

  if [[ -n "${RESUME_REPO_TOKEN}" && "${RESUME_REPO_URL}" == https://github.com/* ]]; then
    CLONE_URL="https://x-access-token:${RESUME_REPO_TOKEN}@github.com/${RESUME_REPO_URL#https://github.com/}"
  fi

  git clone --depth 1 "${CLONE_URL}" "${REPO_DIR}"
fi

SOURCE_TEX_PATH="${REPO_DIR}/${RESUME_SOURCE_TEX}"
TARGET_PDF_PATH="${SITE_DIR}/static/${SITE_CV_FILENAME}"

mkdir -p "$(dirname "${TARGET_PDF_PATH}")"

latest_pdf_in_repo() {
  find "${REPO_DIR}" -maxdepth 2 -type f -name '*.pdf' -exec ls -t {} + | head -n 1
}

if [[ -f "${SOURCE_TEX_PATH}" && "$(command -v latexmk || true)" != "" ]]; then
  echo "Building PDF from ${RESUME_SOURCE_TEX}"
  (
    cd "${REPO_DIR}"
    latexmk -pdf -interaction=nonstopmode -halt-on-error "${RESUME_SOURCE_TEX}"
  )

  LATEST_BUILT_PDF_PATH="$(latest_pdf_in_repo)"

  if [[ -n "${LATEST_BUILT_PDF_PATH}" ]]; then
    cp "${LATEST_BUILT_PDF_PATH}" "${TARGET_PDF_PATH}"
    echo "Updated site CV from built PDF: ${TARGET_PDF_PATH}"
    exit 0
  fi
fi

LATEST_PDF_PATH="$(latest_pdf_in_repo)"

if [[ -z "${LATEST_PDF_PATH}" ]]; then
  echo "No PDF found in ${REPO_DIR} and could not build ${RESUME_SOURCE_TEX}" >&2
  exit 1
fi

cp "${LATEST_PDF_PATH}" "${TARGET_PDF_PATH}"
echo "Updated site CV from existing PDF: ${LATEST_PDF_PATH}"
