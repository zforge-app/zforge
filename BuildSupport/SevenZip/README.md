# 7-Zip estático do Zforge

O snapshot 26.02 em `Vendor/7zip` vem da revisão registrada em `Vendor/7zip-provenance.json`. As fontes upstream não têm patches. O makefile deste diretório adapta o bundle oficial `Format7zF` para um arquivo estático, sem entrypoint de console ou codecs externos. Mantém multithreading, otimização ARM64 do decodificador LZMA e intrinsics de hardware dos codecs.

O app suporta exclusivamente **arm64** e **macOS 26.0 ou superior**. A fase `Build SevenZipCore` usa entradas explícitas em `inputs.xcfilelist`, mantém o sandbox de scripts do Xcode e grava objetos apenas em DerivedData. O linker usa `-force_load` somente na biblioteca para preservar os registros de formatos/codecs. A biblioteca não é copiada ao bundle.

## Recompilar e relinkar

1. Obter as fontes correspondentes completas do Zforge, incluindo `Vendor/7zip`, este diretório e `Zforge/Native`.
2. Abrir `Zforge.xcodeproj` com Xcode que inclua SDK macOS 26 ou posterior.
3. Fazer a alteração desejada nas fontes do motor. Se acrescentar arquivos, incluir os objetos no manifesto e atualizar `inputs.xcfilelist`.
4. Executar `xcodebuild build -project Zforge.xcodeproj -scheme Zforge -configuration Release -destination 'platform=macOS' -derivedDataPath /private/tmp/ZforgeRelink CODE_SIGNING_ALLOWED=NO`. Também é possível selecionar uma identidade de assinatura própria no Xcode.
5. A nova biblioteca será compilada e incorporada ao executável gerado em `Build/Products/Release/Zforge.app`. A assinatura do distribuidor não é necessária para recompilar; assinatura local, acesso ao filesystem e execução seguem as políticas do macOS.

Para compilar só o motor: `bash BuildSupport/SevenZip/build.sh /private/tmp/SevenZipCore Release`.

## Licenças

Consultar integralmente `Vendor/7zip/DOC/License.txt`, `copying.txt` e `unRarLicense.txt`. A ponte Objective-C++ do Zforge é disponibilizada sob LGPL-2.1-or-later. Os avisos upstream BSD/public domain e a restrição unRAR são preservados nas fontes e na licença integral distribuída; RAR é somente leitura. Publicar a fonte correspondente de cada release e seus scripts junto aos materiais de distribuição continua sendo requisito de lançamento.

## Limites

Falha ao decodificar headers criptografados após um pedido de senha pode significar senha inválida ou corrupção desses headers; o domínio preserva o fluxo de senha vigente. Erros de dados de itens não são convertidos genericamente em senha inválida. A execução no mesmo processo implica que falhas nativas fatais podem encerrar o aplicativo.
