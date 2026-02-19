import { notFound } from 'next/navigation';
import WikiWorkspace from '@/components/wiki/wiki-workspace';
import { PAGES_PER_MODULE, TOTAL_WIKI_PAGES, getModulePages, getWikiPage } from '@/lib/wiki';

interface ModuleRunbookPageProps {
  params: {
    page: string;
  };
}

export function generateStaticParams() {
  return Array.from({ length: TOTAL_WIKI_PAGES }, (_, index) => ({
    page: String(index + 1),
  }));
}

export default function ModuleRunbookPage({ params }: ModuleRunbookPageProps) {
  const pageNumber = Number(params.page);
  if (!Number.isInteger(pageNumber)) {
    notFound();
  }

  const page = getWikiPage(pageNumber);
  if (!page) {
    notFound();
  }

  const moduleTabs = getModulePages(page.moduleNumber).map((item) => ({
    label: `P${((item.pageNumber - 1) % PAGES_PER_MODULE) + 1} ${item.categoryShortLabel}`,
    pageNumber: item.pageNumber,
    path: item.path,
    accent: item.categoryAccent,
  }));

  return (
    <div className="mx-auto max-w-6xl px-4 py-12 sm:px-6 lg:px-8">
      <WikiWorkspace
        page={page}
        totalPages={TOTAL_WIKI_PAGES}
        moduleTabs={moduleTabs}
        basePath="/labs"
        indexPath="/labs#module-runbook"
        indexLabel="Back to Modules"
      />
    </div>
  );
}
