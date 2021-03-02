#!/bin/bash

set -e

pip install -U pip==20.2.4

PIP_DOWNLOAD_CMD="pip download --no-deps --disable-pip-version-check"

mkdir -p dist

(
    cd dist

    if [[ -z "${PYDANTIC_VERSION}" ]]; then
        echo "Set the PYDANTIC_VERSION environment variable."
        exit 1
    fi

    echo "slimming wheels for pydantic version ${PYDANTIC_VERSION}"
   
    $PIP_DOWNLOAD_CMD --python-version 3.9 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    $PIP_DOWNLOAD_CMD --python-version 3.8 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    $PIP_DOWNLOAD_CMD --python-version 3.7 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}

    # We can't specify `--python-version` for the 3.6 version because there is some strange bug which prevents
    # it from finding matching packages, so instead we just use a 3.6 base image
    $PIP_DOWNLOAD_CMD --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    #$PIP_DOWNLOAD_CMD --python-version 3.6 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}

    for filename in ./*.whl
    do
        wheel unpack $filename
        strip pydantic-${PYDANTIC_VERSION}/pydantic/*.so
        wheel pack pydantic-${PYDANTIC_VERSION}

        rm -r pydantic-${PYDANTIC_VERSION}
    done

    pip uninstall -y --disable-pip-version-check pydantic
    pip install \
        --disable-pip-version-check \
        pydantic==${PYDANTIC_VERSION} \
        -f . \
        --index-url https://westonsteimel.github.io/pypi-repo \
        --extra-index-url https://pypi.org/pypi

    python -c "
import pydantic
print(pydantic.version.version_info())
"
)
