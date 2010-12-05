title: XMLDSIG in the .NET framework


I was recently given the task on one of my projects at work, to implement a new version of
a digital signature solution that we use to get legally binding signatures" from users.
As part of the upgrade process, I had to implement support for
[XMLDSIG](http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/).

To my great joy, I discovered that the .NET framework has supported XMLDSIG for years, but
I quickly got into problems and all of the documentation I found online, including the
official MSDN documentation covering the XMLDSIG support was either lacking or incorrect.~

### What is XMLDSIG?
Before I get to the code, and the problems I encountered, I'll briefly explain the concept
of XMLDSIG; [XMLDSIG is an old standard](http://www.w3.org/Signature/Drafts/WD-xmldsig-core-20000114/)
in Internet years, and is seemingly accepted as the best and easiest way of digitally
signing XML documents.

The signature can distributed in three different variants;

1. [Enveloped signature](http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/#def-SignatureEnveloped)
   -- the signature is added to the document that was signed.
2. [Enveloping signature](http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/#def-SignatureEnveloping)
   -- the signature contains the document that was signed.
3. [Detached signature](http://www.w3.org/TR/2008/REC-xmldsig-core-20080610/#def-SignatureDetached)
   -- the signature is distributed separate from the document that was signed.

The differences are rather subtle, but there are many transformations that can be applied
to the document prior to signing, and only the right combinations provide valid signatures,
and that is one of the problems I encountered with the
[problematic MSDN documentation](http://msdn.microsoft.com/en-us/library/system.security.cryptography.xml.signedxml.aspx).

### Enveloping != Enveloped
The problem with the MSDN documentation, and virtually every other example of doing
XMLDSIG in .NET, is that they are only based around the "enveloped signature" variant,
even when they tell you they are showing you an example of the "enveloping signature"
variant. Either the authors of the examples have misunderstood the XMLDSIG specification,
or have mistakenly used the word "enveloping", when they should have used "enveloped."

The problem is that, most, if not all, of the authors tell you they are showing you an
example of the enveloping variant, they are instead using some freakish hybrid variant,
and the only reason the sample actually works, is because they are combining the enveloped
and enveloping variants. Any attempt to validate the signature without the context of the
parent document, will fail.

One approach for generating valid enveloping signatures, is to utilize a different
transform that is designed to work with the enveloping variant. The transform I ended up
using was the [Exclusive XML Canonicalization](http://www.w3.org/TR/2002/REC-xml-exc-c14n-20020718/)
transform, as it lends itself very well to extracting the enveloped document and using it
in another context.

    public static class XmlDsig
    {
        private const LoadOptions SafeLoadOptions = LoadOptions.PreserveWhitespace;
        private const SaveOptions SafeSaveOptions = SaveOptions.DisableFormatting;


        public static XDocument SignDocument(XDocument originalDocument,
                                             X509Certificate2 certificate)
        {
            if (originalDocument.Root == null) {
                throw new ArgumentException(
                    "Invalid XML document; no root element found.", "originalDocument");
            }

            SignedXml signature = GetSignature(originalDocument, certificate);
            XDocument signatureDocument = GetSignedDocument(signature);

            VerifySignature(signatureDocument, certificate);

            return signatureDocument;
        }


        private static SignedXml GetSignature(XNode originalDocument,
                                              X509Certificate2 certificate)
        {
            XmlDocument document = GetXmlDocument(originalDocument);
            if (document.DocumentElement == null) {
                throw new InvalidOperationException(
                    "Invalid XML document; no root element found.");
            }

            var signedXml = new SignedXml(document);
            var dataObject = new DataObject("message", "", "", document.DocumentElement);

            signedXml.AddReference(GetSignatureReference());
            signedXml.AddObject(dataObject);
            signedXml.SigningKey = certificate.PrivateKey;
            signedXml.KeyInfo = GetCertificateKeyInfo(certificate);
            signedXml.SignedInfo.CanonicalizationMethod = SignedXml.XmlDsigExcC14NTransformUrl;
            signedXml.ComputeSignature();

            return signedXml;
        }


        private static XmlDocument GetXmlDocument(XNode originalDocument)
        {
            var document = new XmlDocument { PreserveWhitespace = true };
            document.LoadXml(originalDocument.ToString(SafeSaveOptions));

            return document;
        }


        private static Reference GetSignatureReference()
        {
            var signatureReference = new Reference("#message");
            signatureReference.AddTransform(new XmlDsigExcC14NTransform());

            return signatureReference;
        }


        private static KeyInfo GetCertificateKeyInfo(X509Certificate certificate)
        {
            var certificateKeyInfo = new KeyInfo();
            certificateKeyInfo.AddClause(new KeyInfoX509Data(certificate));

            return certificateKeyInfo;
        }


        private static XDocument GetSignedDocument(SignedXml signedXml)
        {
            string signatureXml = signedXml.GetXml().OuterXml;
            XDocument signedDocument = XDocument.Parse(signatureXml, SafeLoadOptions);

            return signedDocument;
        }


        private static void VerifySignature(XNode signedDocument,
                                            X509Certificate2 certificate)
        {
            var document = new XmlDocument { PreserveWhitespace = true };
            document.LoadXml(signedDocument.ToString(SafeSaveOptions));
            if (document.DocumentElement == null) {
                throw new InvalidOperationException(
                    "Invalid XML document; no root element found.");
            }

            var signedXml = new SignedXml(document);
            signedXml.LoadXml(document.DocumentElement);
            if (!signedXml.CheckSignature(certificate, true)) {
                throw new InvalidOperationException("Signature is invalid.");
            }
        }
    }

I had to make another little adjustment to get everything to work correctly, and that was
explicitly setting the canonicalization method. Changing the transform, also solved
another problem I encountered; the inability to reference the object elements by URI ID,
as the default behavior when using the enveloped variant is to look for elements matching
the URI ID within the document being signed, instead of within the signature.

### But what if I want to use the "enveloped signature" variant?
If you don't want the variant I needed (enveloping), then changing the code sample above
to produce signatures of the enveloped kind, is trivial; first make sure to remove the
following two lines:

    signedXml.AddObject(dataObject);
    signedXml.SignedInfo.CanonicalizationMethod = SignedXml.XmlDsigExcC14NTransformUrl;

The next step is to change the GetSignatureReference method; we need to replace the
transform implementation with something that is suitable for the enveloped signature.

    private static Reference GetSignatureReference()
    {
        var signatureReference = new Reference();
        signatureReference.AddTransform(new XmlDsigEnvelopedSignatureTransform());

        return signatureReference;
    }

We also need to add an extra argument to the GetSignedDocument method, so that we can pass
in the original document.

    private static XDocument GetSignedDocument(XNode originalDocument, SignedXml signedXml)
    {
        string signatureXml = signedXml.GetXml().OuterXml;
        XElement signatureElement = XElement.Parse(signatureXml, SafeLoadOptions);
        XDocument signedDocument = XDocument.Load(
            originalDocument.CreateReader(),
            SafeLoadOptions);
        if (signedDocument.Root == null) {
            throw new InvalidOperationException("Invalid XML document; no root element found.");
        }

        signedDocument.Root.Add(signatureElement);

        return signedDocument;
    }

If you spot any errors, please let me know, so that there can exist at least one correct
example of using XMLDSIG in the .NET framework.
