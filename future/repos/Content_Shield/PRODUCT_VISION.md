# Content Shield — Product Vision
## Iron Forge Studios / Joshua 7
Date captured: February 19, 2026

## The Core Breakthrough

The Forbidden Phrase Detector as currently built is a blunt instrument. It flags a word and calls it bad.

The real insight: Context determines whether a word belongs.

A hospital document about overdose treatment is supposed to say "opioid."
A university research paper on radicalization is supposed to say "extremism."
A government brief on child trafficking is supposed to say things that would get a YouTube video pulled.
A church counseling guide on addiction is supposed to talk about drugs.

That is not a violation. That is the entire point of the document.

## What Content Shield Actually Is

Pre-publication AI content validation engine for high-stakes institutional publishers.

Not YouTube creators. Not text messages. Not social media posts.

The real customers:
- Hospitals and healthcare systems
- - Universities and colleges
  - - Government agencies
    - - Churches and faith organizations
      - - Legal institutions
        - - Any organization that publishes documents that affect real people's lives
         
          - ## What the Engine Needs (Missing Right Now)
         
          - The engine needs three layers of context:
         
          - 1. Organizational Context: Who is publishing this?
            2. A hospital word list is different from a school. A law firm differs from a church. Each org defines what is permitted.
           
            3. 2. Document Type Context: What kind of document is this?
               3. Clinical protocol has different rules than a press release. Legal brief differs from a sermon. Same org, different standards per doc type.
              
               4. 3. Audience Context: Who is reading this?
                  4. Medical staff vs. patients vs. public. Adults vs. children. A word correct in a hospital chart is a crisis in a school newsletter.
                 
                  5. ## The Principle
                 
                  6. "A banned word is only banned in the wrong context. Content Shield's job is to know the difference."
                 
                  7. ## What Was Already Built
                 
                  8. - Forbidden Phrase Detector: flags banned words (needs the context layer)
                     - - PII Validator: finds emails, SSNs, phone numbers (never leaks them back)
                       - - Brand Voice Scorer: scores content against the org voice profile
                         - - Prompt Injection Detector: catches hidden attacks in documents
                           - - Readability Scorer: Flesch-Kincaid grade level gate per audience
                            
                             - The foundation is solid. What is missing is the context layer.
                            
                             - ## Next Step
                            
                             - Build the Organizational Context System:
                             - - Org profile (who are you)
                               - - Document type registry (what kind of document)
                                 - - Audience profile (who is reading)
                                   - - Per-org, per-doctype, per-audience rule sets
                                    
                                     - This turns Joshua 7 from a generic scanner into a product hospitals, universities, governments, and churches will pay for.
                                    
                                     - Built with faith. Proceeds support St. Jude's Children's Hospital.
