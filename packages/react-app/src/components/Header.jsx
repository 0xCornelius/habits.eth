import { PageHeader } from "antd";
import React from "react";

// displays a page header

export default function Header({link, title, subTitle}) {
  return (
    <a href={link} target="_blank" rel="noopener noreferrer">
      <PageHeader
        title={title}
        subTitle={subTitle}
        style={{ cursor: "pointer" }}
      />
    </a>
  );
}


Header.defaultProps = {
  link: "https://github.com/austintgriffith/scaffold-eth",
  title: "habits.eth",
  subTitle: "A descentralized way of commiting and tricking your habits built with 🏗 scaffold-eth",
}