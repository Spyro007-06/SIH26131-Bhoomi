import { useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { ArrowLeft, SearchX } from 'lucide-react';
import { useCase, useConfirmCase, useRequestInfo } from '../hooks';
import { CaseHeader } from '../components/CaseHeader';
import { FarmContext } from '../components/FarmContext';
import { ProblemSummary } from '../components/ProblemSummary';
import { HypothesesPanel } from '../components/HypothesesPanel';
import { GateSummary } from '../components/GateSummary';
import { EvidenceGallery } from '../components/EvidenceGallery';
import { FieldObservations } from '../components/FieldObservations';
import { TreatmentsTried } from '../components/TreatmentsTried';
import { LabelChecks } from '../components/LabelChecks';
import { FollowupTrend } from '../components/FollowupTrend';
import { CaseActionBar } from '../components/CaseActionBar';
import { ConfirmCaseDialog } from '../components/ConfirmCaseDialog';
import { CorrectCaseDialog } from '../components/CorrectCaseDialog';
import { RequestInfoDialog } from '../components/RequestInfoDialog';
import { ResolutionSuccessModal } from '../components/ResolutionSuccessModal';
import { Skeleton } from '@/components/ui/Skeleton';
import { ErrorState } from '@/components/feedback/ErrorState';
import { isBhoomiApiError } from '@/lib/api/errors';
import { CaseConfirmRequest, CaseConfirmResponse, CaseRequestInfoRequest } from '@/types/api';

export function CaseWorkspacePage() {
  const { caseId = '' } = useParams<{ caseId: string }>();

  // Dialog & Resolution state
  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [isCorrectOpen, setIsCorrectOpen] = useState(false);
  const [isRequestInfoOpen, setIsRequestInfoOpen] = useState(false);
  const [resolutionResult, setResolutionResult] = useState<CaseConfirmResponse | null>(null);

  // Queries & Mutations
  const { data: caseBundle, isLoading, isError, error, refetch } = useCase(caseId);
  const confirmMutation = useConfirmCase(caseId);
  const requestInfoMutation = useRequestInfo(caseId);

  const isPending = confirmMutation.isPending || requestInfoMutation.isPending;

  // Handlers
  const handleConfirmSubmit = async (payload: CaseConfirmRequest) => {
    try {
      const response = await confirmMutation.mutateAsync(payload);
      setIsConfirmOpen(false);
      setResolutionResult(response);
    } catch {
      // Error is captured in confirmMutation.error and presented in dialog
    }
  };

  const handleCorrectSubmit = async (payload: CaseConfirmRequest) => {
    try {
      const response = await confirmMutation.mutateAsync(payload);
      setIsCorrectOpen(false);
      setResolutionResult(response);
    } catch {
      // Error is captured in confirmMutation.error and presented in dialog
    }
  };

  const handleRequestInfoSubmit = async (payload: CaseRequestInfoRequest) => {
    try {
      await requestInfoMutation.mutateAsync(payload);
      setIsRequestInfoOpen(false);
    } catch {
      // Error is captured in requestInfoMutation.error and presented in dialog
    }
  };

  // Loading Skeleton State
  if (isLoading) {
    return (
      <div className="space-y-6 pb-20 max-w-7xl mx-auto">
        <div className="flex items-center justify-between border-b border-bhoomi-border pb-4">
          <Skeleton className="h-8 w-64 rounded-xl" />
          <Skeleton className="h-6 w-32 rounded-full" />
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          <div className="lg:col-span-7 space-y-6">
            <Skeleton className="h-36 rounded-2xl" />
            <Skeleton className="h-28 rounded-2xl" />
            <Skeleton className="h-80 rounded-2xl" />
            <Skeleton className="h-44 rounded-2xl" />
          </div>
          <div className="lg:col-span-5 space-y-6">
            <Skeleton className="h-64 rounded-2xl" />
            <Skeleton className="h-44 rounded-2xl" />
          </div>
        </div>
      </div>
    );
  }

  // Error States (404, 403, 5xx, Network)
  if (isError || !caseBundle) {
    if (isBhoomiApiError(error) && error.isNotFound()) {
      return (
        <div className="flex flex-col items-center justify-center p-12 text-center rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card space-y-4 my-8 max-w-lg mx-auto">
          <div className="flex h-14 w-14 items-center justify-center rounded-full bg-amber-100 text-amber-800 border border-amber-300">
            <SearchX className="h-7 w-7" />
          </div>
          <div className="space-y-1">
            <h2 className="text-xl font-bold text-bhoomi-text-primary">Case Not Found</h2>
            <p className="text-xs text-bhoomi-text-muted max-w-sm">
              The case identifier <span className="font-mono font-semibold text-bhoomi-text-secondary">{caseId}</span> does not exist or has been archived.
            </p>
          </div>
          <Link
            to="/agronomist/cases"
            className="inline-flex items-center gap-2 rounded-xl bg-bhoomi-primary px-4 py-2.5 text-xs font-semibold text-white hover:bg-bhoomi-primary-dark transition-colors shadow-sm"
          >
            <ArrowLeft className="h-4 w-4" />
            <span>Back to Case Queue</span>
          </Link>
        </div>
      );
    }

    const isForbidden = isBhoomiApiError(error) && error.isForbidden();
    return (
      <ErrorState
        error={error}
        title={isForbidden ? 'Access Restricted' : 'Error Loading Case Bundle'}
        onRetry={() => refetch()}
      />
    );
  }

  const isResolved = caseBundle.status === 'resolved' || resolutionResult !== null;

  return (
    <div className="space-y-6 pb-20 max-w-7xl mx-auto">
      {/* 1. Header & Identity */}
      <CaseHeader
        caseId={caseBundle.case_id}
        status={caseBundle.status}
        openedAt={caseBundle.problem.opened_at}
        isResolved={isResolved}
      />

      {/* 2. Main Two-Column Evidence Workspace */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left Column: Context & Field Records */}
        <div className="lg:col-span-7 space-y-6">
          {/* Farm Context */}
          <FarmContext farm={caseBundle.farm} />

          {/* Problem Summary */}
          <ProblemSummary problem={caseBundle.problem} />

          {/* Prominent Image Evidence */}
          <EvidenceGallery images={caseBundle.images} />

          {/* Doubt Doctor Field Observations */}
          <FieldObservations observations={caseBundle.field_observations} />

          {/* Treatments Tried */}
          <TreatmentsTried treatments={caseBundle.treatments_tried} />

          {/* Pesticide Label Checks */}
          <LabelChecks labelChecks={caseBundle.label_checks} />

          {/* Follow-up Trend */}
          <FollowupTrend
            trend={caseBundle.followup_trend}
            spokenSummary={caseBundle.spoken_summary}
          />
        </div>

        {/* Right Column: AI Hypotheses & Gate Context (Sticky on Desktop) */}
        <div className="lg:col-span-5 space-y-6 lg:sticky lg:top-24">
          {/* Model Hypotheses */}
          <HypothesesPanel hypotheses={caseBundle.model_hypotheses} />

          {/* Decision Gate */}
          <GateSummary gate={caseBundle.gate} />
        </div>
      </div>

      {/* 3. Sticky Action Bar */}
      <CaseActionBar
        onConfirmClick={() => setIsConfirmOpen(true)}
        onCorrectClick={() => setIsCorrectOpen(true)}
        onRequestInfoClick={() => setIsRequestInfoOpen(true)}
        isPending={isPending}
        isResolved={isResolved}
      />

      {/* 4. Action Dialogs */}
      <ConfirmCaseDialog
        isOpen={isConfirmOpen}
        onClose={() => setIsConfirmOpen(false)}
        onConfirm={handleConfirmSubmit}
        caseId={caseBundle.case_id}
        targetLabel={caseBundle.problem.label}
        isPending={confirmMutation.isPending}
        error={confirmMutation.error as Error | null}
      />

      <CorrectCaseDialog
        isOpen={isCorrectOpen}
        onClose={() => setIsCorrectOpen(false)}
        onCorrect={handleCorrectSubmit}
        caseId={caseBundle.case_id}
        currentLabel={caseBundle.problem.label}
        isPending={confirmMutation.isPending}
        error={confirmMutation.error as Error | null}
      />

      <RequestInfoDialog
        isOpen={isRequestInfoOpen}
        onClose={() => setIsRequestInfoOpen(false)}
        onRequestInfo={handleRequestInfoSubmit}
        caseId={caseBundle.case_id}
        isPending={requestInfoMutation.isPending}
        error={requestInfoMutation.error as Error | null}
      />

      {/* 5. Resolution Success Modal */}
      <ResolutionSuccessModal
        isOpen={resolutionResult !== null}
        resolution={resolutionResult}
        onClose={() => setResolutionResult(null)}
      />
    </div>
  );
}
