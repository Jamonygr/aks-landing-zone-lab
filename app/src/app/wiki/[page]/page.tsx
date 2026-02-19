import { notFound, redirect } from 'next/navigation';
import { TOTAL_WIKI_PAGES } from '@/lib/wiki';

interface WikiPageProps {
  params: {
    page: string;
  };
}

export function generateStaticParams() {
  return Array.from({ length: TOTAL_WIKI_PAGES }, (_, index) => ({
    page: String(index + 1),
  }));
}

export default function WikiGuidePage({ params }: WikiPageProps) {
  const pageNumber = Number(params.page);
  if (!Number.isInteger(pageNumber)) {
    notFound();
  }
  if (pageNumber < 1 || pageNumber > TOTAL_WIKI_PAGES) {
    notFound();
  }
  redirect(`/labs/${pageNumber}`);
}
