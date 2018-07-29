#!/usr/bin/env bash
cat <<EOF
################################################################################
Development tools
################################################################################
EOF

bash "${DOTFILES_DIR:-.}"/installers/setupdocker.sh
bash "${DOTFILES_DIR:-.}"/installers/setupdocker-compose.sh
bash "${DOTFILES_DIR:-.}"/installers/setupexa.sh
bash "${DOTFILES_DIR:-.}"/installers/setupvim.sh python3

bash "${DOTFILES_DIR:-.}"/recipes/devel-fonts.sh