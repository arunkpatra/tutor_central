import { Icon } from "@/components/Icon";
import { FeatureRow, ListCard, Page, PlainRow, Prose, SecondaryLink, Section, TextLink } from "@/components/parts";
import { HOME } from "@/content/home";
import { EMAIL, ROUTES } from "@/content/site";
import { appStoreURL } from "@/lib/env";

/** Apple's badge once the app is live (D47), else the email call to action, as P8-Home and P8-Home-Badge draw. The badge's
 *  black, white and #A6A6A6 rim are Apple's (components.md), the site's one set of colours outside the tokens. */
function CallToAction() {
  const store = appStoreURL();
  if (store) {
    return (
      <div className="actions">
        <a
          href={store}
          aria-label="Download on the App Store"
          style={{
            textDecoration: "none",
            display: "inline-flex",
            alignItems: "center",
            gap: 10,
            height: 52,
            padding: "0 18px 0 14px",
            borderRadius: 12,
            background: "#000000",
            color: "#FFFFFF",
            border: "1px solid #A6A6A6",
          }}
        >
          <Icon name="apple" size={26} width={1.6} />
          <span style={{ display: "flex", flexDirection: "column", lineHeight: 1 }}>
            <span style={{ fontSize: 11 }}>Download on the</span>
            <span style={{ fontSize: 21, fontWeight: 600, letterSpacing: "-0.01em" }}>App Store</span>
          </span>
        </a>
        <p className="small">{HOME.badgeLine}</p>
      </div>
    );
  }
  return (
    <div className="cta">
      <SecondaryLink href={`mailto:${EMAIL}`} icon="mail">
        Email {EMAIL}
      </SecondaryLink>
      <p className="small">{HOME.comingSoon}</p>
    </div>
  );
}

export default function Home() {
  return (
    <Page current="">
      <section className="wrap heroWrap">
        <div className="glow" aria-hidden="true" />
        <div className="hero">
          <div className="heroText">
            <h1 className="h1">{HOME.headline}</h1>
            <p className="lead">{HOME.lead}</p>
            <CallToAction />
          </div>
          <div className="phone">
            {/* biome-ignore lint/performance/noImgElement: a static export has no image optimiser; the one picture is already sized. */}
            <img src="/today-dark.png" width={393} height={852} alt={HOME.phoneAlt} />
          </div>
        </div>
      </section>
      <Section>
        <h2 className="h2">What it does</h2>
        <ListCard>
          {HOME.features.map((f) => (
            <FeatureRow key={f.title} icon={f.icon} title={f.title} line={f.line} />
          ))}
        </ListCard>
      </Section>
      <Section>
        <h2 className="h2">Made for how a tutor works</h2>
        <div className="cols3">
          {HOME.how.map((h) => (
            <PlainRow key={h.title} title={h.title} line={h.line} />
          ))}
        </div>
      </Section>
      <Section>
        <h2 className="h2">What it does not do</h2>
        <div className="cols2 notCols">
          {HOME.not.map((n) => (
            <PlainRow key={n.title} title={n.title} line={n.line} />
          ))}
        </div>
        <p className="rowLine">
          {HOME.notLink}
          <TextLink href={ROUTES.privacy}>{HOME.notLinkWords}</TextLink>.
        </p>
      </Section>
      <Section>
        <h2 className="h2">Who makes it</h2>
        <Prose>
          <p>{HOME.maker}</p>
          <p>
            {HOME.write}
            <TextLink href={`mailto:${EMAIL}`}>{EMAIL}</TextLink>
            {HOME.writeAfter}
          </p>
        </Prose>
      </Section>
    </Page>
  );
}
