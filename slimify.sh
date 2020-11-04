#!/bin/bash

set -e

PIP_DOWNLOAD_CMD="pip download --no-deps --disable-pip-version-check"

mkdir -p dist

(
    cd dist

    if [[ -z "${PYDANTIC_VERSION}" ]]; then
        PYDANTIC_VERSION=$(pip search pydantic | pcregrep -o1 -e "^pydantic \((.*)\).*$")
    fi

    echo "slimming wheels for pydantic version ${PYDANTIC_VERSION}"
   
    $PIP_DOWNLOAD_CMD --python-version 3.9 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    $PIP_DOWNLOAD_CMD --python-version 3.8 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    $PIP_DOWNLOAD_CMD --python-version 3.7 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}
    $PIP_DOWNLOAD_CMD --python-version 3.6 --platform manylinux2014_x86_64 pydantic==${PYDANTIC_VERSION}

    for filename in ./*.whl
    do
        wheel unpack $filename
        strip pydantic-${PYDANTIC_VERSION}/pydantic/*.so
        wheel pack pydantic-${PYDANTIC_VERSION}

        rm -r pydantic-${PYDANTIC_VERSION}
    done

    pip uninstall -y --disable-pip-version-check pydantic
    pip install --disable-pip-version-check pydantic==${PYDANTIC_VERSION} -f .

    python -c "
import pydantic
print(pydantic.version.version_info())
"
)
